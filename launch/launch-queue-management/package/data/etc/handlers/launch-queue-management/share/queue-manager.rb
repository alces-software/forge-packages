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
require 'open3'

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
class OperationInProgress < RuntimeError; end

class Result < Struct.new(:output, :status)
  def operation_in_progress?
    output =~ /operation in progress/
  end

  def success?
    status.exitstatus == 0
  end
end

class Resource < Struct.new(:id, :type, :attributes, :links, :auth_user, :auth_password)
  def self.build(jsonapi_doc, auth_user, auth_password)
    attributes = OpenStruct.new(jsonapi_doc['attributes'])
    links = OpenStruct.new(jsonapi_doc['links'])
    new(jsonapi_doc['id'], jsonapi_doc['type'], attributes, links, auth_user, auth_password)
  end

  def patch(new_attributes)
    uri = URI(links.self)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      req = Net::HTTP::Patch.new(uri)
      req.content_type = 'application/vnd.api+json'
      req.basic_auth(auth_user, auth_password)
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

def download_pending_actions(endpoint, auth_user, auth_password)
  uri = URI(endpoint)
  uri.query = [
    uri.query,
    'filter[status]=PENDING',
    'filter[action]=CREATE,MODIFY,DELETE',
    'sort=createdAt',
  ].compact.join('&')
  log("Downloading pending compute queue actions from #{uri}")
  body = open(
    uri.to_s,
    http_basic_authentication: [auth_user, auth_password]
  ).read
  JSON.parse(body)
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
    ]
    Result.new(*Open3.capture2e(*cmd)).tap do |result|
      result.output.lines.each {|line| log(line.chomp)}
      raise Retry.new if result.operation_in_progress?
    end
  rescue Retry
    if (@retries += 1) < 20
      log('Operation in progress; retrying in 6s...')
      sleep 6
      retry
    else
      raise OperationInProgress
    end
  end
end

def main(endpoint, auth_user, auth_password)
  begin
    response = download_pending_actions(endpoint, auth_user, auth_password)
  rescue OpenURI::HTTPError, Errno::ECONNREFUSED
    log("Download failed: #{$!.message}")
  else
    log("Processing #{response['data'].length} pending actions")
    resources = response['data'].map do |qa|
      Resource.build(qa, auth_user, auth_password)
    end
    resources.each do |queue_action|
      queue_action.patch(status: 'IN_PROGRESS')
      begin
        result = process_queue_action(queue_action)
      rescue OperationInProgress
        # The action was not accepted due to another being in progress.
        # Setting its status back to PENDING and aborting all other actions
        # ensures that we will eventually process the actions in the correct
        # order.
        log('Operation in progress; aborting all further processing')
        queue_action.patch(status: 'PENDING')
        break
      else
        if result.success?
          queue_action.patch(status: 'COMPLETE')
        else
          cleaned_output = result.output.gsub(/\e\[[0-9;]*m/, '')
          queue_action.patch(status: 'FAILED', output: cleaned_output)
        end
      end
    end
    log("Processing completed")
  ensure
    @log && @log.close
  end
end

if __FILE__ == $0
  $ALCES = ARGV[0]
  endpoint = ARGV[1]
  auth_user = ARGV[2]
  auth_password = ARGV[3]

  main(endpoint, auth_user, auth_password)
end
