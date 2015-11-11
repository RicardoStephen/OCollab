(*Cursor position*)
type position

(*Handler for inserting or deleting text at certain position - will use CodeMirror*)
val handle_edit_event : unit -> unit

val apply_patches : patch list -> unit

(* Sending patches to server*)  (*send: a patch and cursor position, receive: patch list from server  *)
val patches_to_server : patch list -> position -> unit

