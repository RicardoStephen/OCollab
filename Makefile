
# Bytecode compiler
OCC=ocamlfind ocamlc
# Native compiler
OCN=ocamlfind ocamlopt

# Client side packages
CLIENT_PKGS=
# Server side packages
SERVER_PKGS=yojson,redis,eliom.server
# Unit test packages
TEST_PKGS=pa_ounit,yojson,redis

TEST_LIBS=storage.cmx document.cmx serializer.cmx assertions.cmx

.PHONY: all

.PRECIOUS: %.cmi %.cmo %.cmx %.o

all: run

compile: server client.js

server: patch.cmo document.cmo storage.cmo editor.cmo

client.js:
	cp patch.mli patch.ml document.mli document.ml client
	cd client && $(MAKE) && cd ..

test_%: test_%.ml patch.cmx $(TEST_LIBS)
	$(OCN) -o $@ -linkall -thread -linkpkg -package $(TEST_PKGS) -syntax camlp4o patch.cmx -package pa_ounit.syntax $(TEST_LIBS) $< 

%.cmo: %.ml %.cmi
	$(OCC) -o $@ -linkpkg -package $(SERVER_PKGS) -thread -c $<

%.cmx: %.ml %.cmi
	$(OCN) -o $@ -linkpkg -package $(SERVER_PKGS) -thread -c $<

%.cmi: %.mli
	$(OCC) -o $@ -linkpkg -package $(SERVER_PKGS) -thread -c $<

test: compile test_patch test_storage
	./test_patch inline-test-runner dummy -log -verbose
	./test_storage inline-test-runner dummy -log

run: compile
	@-mkdir -p server/log
	@-mkdir -p server/data
	@-mkdir -p server/static
	cp client/_build/client.js server/static/
	cp client/index.html server/static/
	cp -r client/ace-min server/static/
	ocsigenserver -c editor.conf

clean:
	@-rm -r _build
	@-rm -r _cs3110
	@-rm -r server
	@-rm *.cmi
	@-rm *.cmo
	@-rm *.cmx
	@-rm *.cma
	@-rm *.o
	@-rm *.js
	cd client && $(MAKE) clean && cd ..

install:
	opam install -y yojson
	opam install -y js_of_ocaml
	opam depext dbm.1.0
	opam install -y eliom
	sudo apt-get install -y redis-server
	opam install -y redis

