(*
 * Document Module
 * 
 * Provides types for document data, consisting of a unique ID, a list of
 * patches, and the current iteration of a document.
 * 
 * TODO Document optimization (?)
 *)

open Patch

type document_id = string

type document_metadata = {
    title: string
    (* Created, modified, views, etc. *)
  }

type document_text = string

type document = {
    id: document_id;
    metadata: document_metadata;
    patches: patch list;
    text: document_text
  }

(*
 * Converts a document to a string representation.
 *)
val string_of_document : document -> string

(*
 * Converts a document representation to a patch.
 *)
val document_of_string : string -> document
