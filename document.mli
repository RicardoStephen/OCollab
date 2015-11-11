(*
 * Document Module
 *
 * TODO Optimization (or does that go on a higher level?)
 *)

open Async.Std

type doc_id

type doc_key

type doc_metadata

type doc

(*
 * Root directory of the document storage. This variable defaults to
 * Sys.getcwd ^ "/store".
 *)
val root : string

(*
 * Checks if a document id exists in the storage.
 *)
val doc_exists : doc_id -> bool Deferred.t

(*
 * Creates a document and returns its id.
 *)
val doc_create : unit -> doc_id Deferred.t

(*
 * Returns a list of document ids in the storage.
 *)
val get_doc_list : unit -> doc_id list Deferred.t

(*
 * Retrieves a document given an id.
 *)
val get_doc : doc_id -> doc option Deferred.t

(*
 * Retrieves document metadata given an id.
 *)
val get_doc_metadata : doc_id -> doc_metadata

(*
 * Retrieves document patches given an id.
 * Returns the last n patches (or all patches if n is -1.
 *)
val get_doc_patches : doc_id -> int -> Patch.patch list

(*
 * Sets the contents of a document.
 *)
val set_doc : doc_id -> doc -> bool Deferred.t

(*
 * Sets the metadata of a document.
 *)
val set_doc_metadata : doc_id -> doc_metadata -> bool Deferred.t

(*
 * Add patches to a document.
 *)
val add_doc_patches : doc_id -> Patch.patch list -> bool Deferred.t

