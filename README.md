# Velocity
A compiler for Apache Velocity in JavaScript.

The lexical tokens for the Velocity CFG are written using a `flex` specification, while the actual grammar itself is written using a `YACC` specification. The JavaScript parser is auto-generated using `JISON`, a JavaScript parser generator similar in nature to `BISON`. 

In order to create and test the JavaScript parser, make sure you have `JISON` and `Apache Tomcat` installed on your Mac or PC. If they are not installed then use `Homebrew` to install Tomcat and `node` to install JISON.

The commands are:

```
brew install tomcat //for Tomcat
npm install jison -g //for JISON
```


In order to create JavaScript file, type in the following command on commandline:

```
jison velocity.jison
```

This will generate the JavaScript parser based off of the grammar. 


Parser is tested using `parser.html` file in the `parser` file directory. HTML file is run online using an Apache Tomcat server.
To start the server, type in the following on commandline:

```
nohup catalina start &
```
Move `parser.html` somewhere accessible from the tomcat file directory and type the following url into your web browser:

```
http://localhost:8080/path-to-parser.html
```

You should now be able to type in Velocity code and check if it parses or not.

Alternatively parser can be tested in Terminal using the given Makefile and test cases. Makefile has 3 actions:
`make parser` generates the JavaScript parser,
`make test` tests all the .vel test files provided,
`make clean` removes the JavaScript parser from file directory (this is optional).


