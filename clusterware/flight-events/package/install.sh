#!/bin/sh

cp -r data/etc "${cw_ROOT}"
cp -r data/lib "${cw_ROOT}"
cp -r data/libexec "${cw_ROOT}"

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
    data/init/systemd/flight-events.service \
    > /etc/systemd/system/flight-events.service

sed -i -e "s,_cw_ROOT_,${cw_ROOT},g" \
    "${cw_ROOT}"/etc/serf/handlers.json \
    "${cw_ROOT}"/etc/modules/services/events
