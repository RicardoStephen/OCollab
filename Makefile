
.PHONY: all eliom_test


all: test run
	@echo "Nothing here"

compile: gui_test.js
	@echo "Compile"

gui_test.js:
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax \-syntax camlp4o -linkpkg -o _build/gui_test.byte gui_test.ml
	js_of_ocaml _build/gui_test.byte

eliom_test: 
	ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax \-syntax camlp4o -linkpkg -o eliom_test/static/gui_js.byte eliom_test/gui_js.ml
	js_of_ocaml eliom_test/static/gui_js.byte
	cd eliom_test && $(MAKE) test.byte


test: compile
	@echo "Test"

run: compile
	@echo "Run"

clean:
	rm -r _build
	rm -r _cs3110

install:
	opam install -y yojson
	opam install -y js_of_ocaml
	opam depext dbm.1.0
	opam install -y eliom
	sudo apt-get install -y redis-server
	opam install -y redis

