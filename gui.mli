open Interface
open Patch
open Document

(* gui.ml will be compiled to js and will be sent from server to client *)

(* Reference: https://codemirror.net/doc/manual.html, esp. Basic Usage,
   Configuration, Events *)

(*Current user selection*)
type selection

(* Render page before code mirror is fetched *)
val pre_render : unit -> unit

(* Fetches code for the editor from the server *)
val fetch_editor : unit -> unit

(* Fetches the initital document *)
val fetch_document : unit -> unit

(* Handler for inserting or deleting text at certain position - will use
   CodeMirror, which will trigger events*)
val handle_edit_event : unit -> unit

(* Need an event or something that requests for updates from the server. *)
val fetch_updates : response -> unit

val request_updates : request -> (response -> unit) -> unit

(* Instatiate editor instance with desired configurations and handlers *)
val init_editor : unit -> unit


val apply_patches : patch list -> unit

(* Send patch and current user selection to server*)
val patches_to_server : patch list -> selection -> unit
