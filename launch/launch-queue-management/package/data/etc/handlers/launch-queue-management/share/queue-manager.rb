#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
require 'json'
require 'open-uri'
require 'ostruct'

ACTION_TO_COMPUTE_COMMAND = {
  'CREATE' => 'addq',
  'MODIFY' => 'modq',
  'DELETE' => 'delq',
}.freeze

ACTION_TO_VERB = {
  'CREATE' => 'Adding',
  'MODIFY' => 'Modifying',
  'DELETE' => 'Deleting',
}.freeze

class Retry < RuntimeError; end

class Resource < Struct.new(:id, :type, :attributes, :links)
  def self.build(jsonapi_doc)
    attributes = OpenStruct.new(jsonapi_doc['attributes'])
    links = OpenStruct.new(jsonapi_doc['links'])
    new(jsonapi_doc['id'], jsonapi_doc['type'], attributes, links)
  end

  def patch(new_attributes)
    uri = URI(links.self)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      req = Net::HTTP::Patch.new(uri)
      req.content_type = 'application/vnd.api+json'
      req.body = {
        data: {
          id: id,
          type: type,
          attributes: new_attributes
        }
      }.to_json
      http.request(req)
    end
  end
end

@retries = 0

def log(message)
  @log ||= File.open('/var/log/clusterware/queue-manager.log', 'a')
  @log.puts("#{Time.now.strftime('%b %e %H:%M:%S')} #{message}")
end

def download_pending_actions(endpoint)
  uri = URI(endpoint)
  uri.query = [
    uri.query,
    'filter[status]=PENDING',
    'filter[action]=CREATE,MODIFY,DELETE',
    'sort=createdAt',
  ].compact.join('&')
  log("Downloading pending compute queue actions from #{uri}")
  JSON.parse(uri.open.read)
end

def process_queue_action(queue_action)
  qa = queue_action.attributes

  log("#{ACTION_TO_VERB[qa.action]} queue: #{qa.spec} (#{qa.desired}/#{qa.min}-#{qa.max}) (#{queue_action.id})")
  begin
    cmd = [
      $ALCES,
      'compute',
      ACTION_TO_COMPUTE_COMMAND[qa.action],
      qa.spec,
      qa.desired.to_s,
      qa.min.to_s,
      qa.max.to_s,
      :err=>[:child, :out]
    ]
    IO.popen(cmd) do |io|
      while !io.eof?
        line = io.readline
        log(line)
        raise Retry.new if line =~ /operation in progress/
      end
    end
  rescue Retry
    if (@retries += 1) < 20
      log('Operation in progress; retrying in 6s...')
      sleep 6
      retry
    end
  end
end

def main(endpoint)
  begin
    response = download_pending_actions(endpoint)
  rescue OpenURI::HTTPError
    log("Download failed: #{$!.message}")
  else
    log("Processing #{response['data'].length} pending actions")
    response['data'].map{|qa| Resource.build(qa) }.each do |queue_action|
      queue_action.patch(status: 'IN_PROGRESS')
      process_queue_action(queue_action)
      queue_action.patch(status: 'COMPLETE')
    end
  ensure
    @log && @log.close
  end
end

if __FILE__ == $0
  $ALCES = ARGV[0]
  endpoint = ARGV[1]

  main(endpoint)
end
