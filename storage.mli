(*
 * Storage Module
 * 
 * Handles document storage.
 *)

open Document

(*
 * Creates a document and returns its id.
 *)
val document_create : unit -> document_id

(*
 * Returns a list of document ids in the storage.
 *)
val get_document_list : unit -> document_id list

(*
 * Retrieves a document given an id.
 *)
val get_document : document_id -> document option

(*
 * Retrieves document metadata given an id.
 *)
val get_document_metadata : document_id -> document_metadata

(*
 * Retrieves document patches given an id.
 * Returns the last n patches (or all patches if n is -1).
 *)
val get_document_patches : document_id -> int -> patch list

(*
 * Sets the contents of a document.
 *)
val set_document : document_id -> document -> bool

(*
 * Sets the metadata of a document.
 *)
val set_document_metadata : document_id -> document_metadata -> bool

(*
 * Adds patches to a document.
 *)
val add_document_patches : document_id -> patch list -> bool
