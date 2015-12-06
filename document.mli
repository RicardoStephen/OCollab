(**
 * Document Module
 * 
 * Provides types for document data, consisting of a unique ID, a list of
 * patches, and the current iteration of a document.
 * 
 *)

open Patch

type document_id = string

type document_metadata = {
    title: string
}

type document_text = string

type document = {
    id: document_id;
    metadata: document_metadata;
    patches: patch list;
    text: document_text
  }
