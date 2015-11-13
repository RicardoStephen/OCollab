open Interface

val gen_response: doc_id -> patch -> document_text -> response

(* Will delegate to helper functions *)
val handle_request: request -> response

(* Updates the current desired document using the given patches *)
val handle_patch_update: doc_id -> patch -> response

(* Responds to a request for the document text *)
val handle_get_doctext: doc_id -> response

(* To handle the initial request, which will not have a any patches or
 * document text associated with them. *)
val handle_get_init: unit -> response

(* Retrieves the doucment text associated with the given document id *)
val get_document_text: doc_id -> document_text
