open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

let timestamp_now () =
  let now = Clock.gmtime (Clock.time ()) in
  let open Clock in
  (now.tm_year, (now.tm_mon + 1), now.tm_mday), ((now.tm_hour, now.tm_min, now.tm_sec), 0)

module Main (C:CONSOLE) (S:STACKV4) (Clock:V1.CLOCK) (RES: Resolver_lwt.S) (CON: Conduit_mirage.S) = struct

  (*
    If you want to write to the file system, do:
    module LoggerStore = Irmin_unix.Irmin_git.FS(Irmin.Contents.String)(Irmin.Ref.String)(Hash)
    with:
    let store_config = Irmin_git.config ~root:"/tmp/logger" ~bare:true ()
    or whatever directory you want to write to.
    This is useful for debugging :)

    TODO: would be nice to have a `--debug` flag with logger that wrote to FS.
  *)

  let start console s c res con =
    let module Context =
      ( struct
        let v _ = Lwt.return_some (res, con)
      end : Irmin_mirage.CONTEXT)
    in
    let module Hash = Irmin.Hash.SHA1 in
    let module Mirage_git_memory = Irmin_mirage.Irmin_git.Memory(Context)(Inflator) in
    let module LoggerStore = Mirage_git_memory(Irmin.Contents.String)(Irmin.Ref.String)(Hash) in
    let module LoggerSync = Irmin.Sync(LoggerStore) in

    let store_config = Irmin_mem.config () in
    let task s = Irmin.Task.create
        ~date:(Clock.time () |> Int64.of_float)
        ~owner:"Logger" s
    in
    let log_message msg =
      LoggerStore.Repo.create store_config >>= fun r ->
      LoggerStore.master task r >>= fun t ->
      let pretty_msg = Syslog_message.pp_string msg in
      (* See comment below about format *)
      LoggerStore.update (t "Logger") ["--"] pretty_msg >>
      (* Right now, we're just printing the read value we added. *)
      LoggerStore.read (t "Logger") ["--"] >>= fun value ->
      match value with
      | Some value -> C.log_s console (blue "Git stored in Logger: %s" value)
      | None -> C.log_s console (red "No items have been created.")
    in

    let local_port = (Key_gen.port ()) in
    S.listen_udpv4 s ~port:local_port begin fun ~src ~dst ~src_port buf ->
      match Ptime.of_date_time (timestamp_now ()) with
      | Some ts ->
        let ctx = {
          timestamp = ts;
          Syslog_message.hostname = (Ipaddr.V4.to_string src);
          set_hostname = false
        }
        in
        begin
          match Syslog_message.parse ~ctx (Cstruct.to_string buf) with
          | None -> C.log_s console (red "Failed: %s" (Cstruct.to_string buf))
          | Some msg ->
              (*
                  TODO: Think about format here... should it be raw buffer,
                        or structured JSON format? Who should be the commiter?
                        What should the commit message be? Is there other
                        metadata that should be associated with the commit?
              *)
            log_message msg >>
            C.log_s console (green "%s" (Syslog_message.pp_string msg))
        end
      | None -> C.log_s console (red "Failed / Invalid timestamp: %s" (Cstruct.to_string buf))
    end;
    S.listen s
end
