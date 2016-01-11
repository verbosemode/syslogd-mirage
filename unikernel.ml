open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C:CONSOLE) (S:STACKV4) (Clock:V1.CLOCK) = struct
  let start console s c =
    let local_port = 5514 in
    S.listen_udpv4 s local_port (
      fun ~src ~dst ~src_port buf ->
        (* FIXME Warning 40 - was selected from ... not visible ... *)
        let now = Clock.gmtime (Clock.time ()) in
        match (Ptime.of_date_time ((now.tm_year, (now.tm_mon + 1), now.tm_mday), ((now.tm_hour, now.tm_min, now.tm_sec), 0))) with
        | Some ts ->
            let ctx = {timestamp=ts;
              Syslog_message.hostname=(Ipaddr.V4.to_string src);
              set_hostname=false}
            in
            begin match Syslog_message.parse ~ctx (Cstruct.to_string buf) with
            | None -> C.log_s console (red "Failed: %s" (Cstruct.to_string buf))
            | Some msg -> C.log_s console (green "%s" (Syslog_message.pp_string msg))
            end
        | None -> C.log_s console (red "Failed / Invalid timestamp: %s" (Cstruct.to_string buf))
    );

    S.listen s
end
