(*
 * Document Module
 * 
 * Provides types for document data, consisting of a unique ID, a list of
 * patches, and the current iteration of a document.
 * 
 * TODO Document optimization (?)
 *)

open Patch

type document_id

type document_metadata

type document_text

type document

(*
 * Converts a document to a string representation.
 *)
val string_of_document : document -> string

(*
 * Converts a document representation to a patch.
 *)
val document_of_string : string -> document
