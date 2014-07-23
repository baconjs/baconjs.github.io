.PHONY : all dev

COFFEE ?= coffee

all : 
	$(COFFEE) generate.coffee

dev : 
	$(COFFEE) generate.coffee dev
