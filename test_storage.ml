include Patch
include Document
open Storage
open Redis

let ctlopt = storage_open "127.0.0.1" 6379

TEST = match ctlopt with Some _ -> true | None -> false

let ctl = match ctlopt with Some c -> c | None -> failwith "Failed to connect"


