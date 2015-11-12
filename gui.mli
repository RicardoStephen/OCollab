(* ASSUMPTION: gui.ml will be compiled to js and will be sent from server to client *)

(* Reference: https://codemirror.net/doc/manual.html, esp Basic Usage, Configuration, Events *)

(* NOTE: *)
(* Render page before code mirror is fetched *)
val pre_render : unit -> unit

(* Fetches code for the editor from the server *)
val fetch_editor : unit -> unit

(* Fetches the initital document *)
(* QUESTION at the beginnnig, will the client get a document or a bunch of patches it has to
   assembel? If latter, we do not need this method. *)
val fetch_document : unit -> unit


(* Handler for inserting or deleting text at certain position - will use CodeMirror*)
val handle_edit_event : unit -> unit

(* TODO *)
(* Need an event or something that requests for updates from the server. *)

(* Instatiate editor instance with desired configurations and handlers *)
val init_editor : unit -> unit

(* QUESTION *)
(* The event handler will likely fire post/get requests. What on the client side handles them?
   Is there like a javascript object listening for such events? *)

(* CONCERN *)
(* The following code seems very sketch. Idk where patches will fit into
   a file being compiled to js *)

(*Cursor position*)
type position

val apply_patches : patch list -> unit

(* Sending patches to server*)  (*send: a patch and cursor position, receive: patch list from server  *)
val patches_to_server : patch list -> position -> unit

val gen_request: doc_id -> patch -> request
