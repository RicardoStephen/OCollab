(*
 * Document Module
 *
 * TODO Optimization (or does that go on a higher level?)
 *)

open Async.Std

type doc_id = string

type doc_metadata = {
  id : doc_id;
  title : string;
}

type doc = {
  id : string;
  metadata : doc_metadata;
  patches : patch list;
}

(*
 * Root directory of the document storage. This variable defaults to
 * Sys.getcwd ^ "/store".
 *)
val root : string

(*
 * Checks if a document id exists in the storage.
 *)
val exists : doc_id -> bool Deferred.t

(*
 * Creates a document and returns its id.
 *)
val create : unit -> doc_id Deferred.t

(*
 * Returns a list of document ids in the storage.
 *)
val get_list_documents : unit -> doc_id list Deferred.t

(*
 * Retrieves a document given an id.
 *)
val get : doc_id -> doc option Deferred.t

(*
 * Retrieves document metadata given an id.
 *)
val get_metadata : doc_id -> doc_metadata

(*
 * Retrieves document patches given an id.
 *)
val get_patches : doc_id -> patch list

(*
 * Sets the contents of a document.
 *)
val set : doc_id -> doc -> bool Deferred.t

(*
 * Sets the metadata of a document.
 *)
val set_metadata : doc_id -> doc_metadata -> bool Deferred.t

(*
 * Sets the patch list of a document.
 *)
val set_patches : doc_id -> patch list -> bool Deferred.t
