build:
	sphinx-build -M html docs/source/ docs/build/

run: build 
	
	google-chrome docs/build/html/index.html 
