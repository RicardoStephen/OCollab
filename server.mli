open Interface

val gen_response: doc_id -> patch -> document_text -> response

val handle_request: request -> response

val handle_patch_update: doc_id -> patch -> response

val handle_get_doctext: doc_id -> response

(* To handle the initial request, which will not have a any
 * patches. *)
val handle_get_init: unit -> response

val get_document_text: doc_id -> document_text
