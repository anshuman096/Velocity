
/* description: Parses and executes mathematical expressions. */


/* lexical grammar */
%lex
%options flex


DIGIT               [0-9]
LETTER              [a-zA-Z\_\-]
SLETTER             [a-zA-Z]
NEWLINE             \n
SPACE               \s
PUNCT		    [!%$&+,-/:;<=>?@[\]^_`|(){}~.]

%x INITIAL INSTRING SWITCH SL_COMMENT ML_COMMENT
%%
{NEWLINE}+                    /* skip newlines */
{SPACE}+                      /* skip whitespaces */
"#"                           { this.begin("SWITCH"); return 'HASH' } /* SWITCH into either Velocity statements or comments */
"$"                   	      { return 'VARBEGIN' } /* Beginning of a variable declaration */

/* SINGLEQUOTE and DOUBLEQUOTE represent beginning and end of a string literal */
"'"                           { this.begin("INSTRING"); return 'SINGLEQUOTE'}
"\""                          { this.begin("INSTRING"); return 'DOUBLEQUOTE'}

/* Within SWITCH state, if HASH is scanned -> SINGLE LINE COMMENT, if '**' scanned -> MULTI LINE COMMENT */
<SWITCH>"#"                   { this.popState(); this.begin("SL_COMMENT"); return 'COMMENT_START' }
<SWITCH>"**"	              { this.popState(); this.begin("ML_COMMENT"); return 'COMMENT_START' }

/* SINGLE LINE COMMENT can have letters, numbers, punctuations, or spaces
   Pop out of SL_COMMENT state at end of comment, SL_COMMENT only has one line */
<SL_COMMENT>(({SLETTER}|{DIGIT}|{PUNCT}|{SPACE})*)
                              { console.log("End of Comment"); this.popState(); return 'SL_COMMENT'}

/* MULTI LINE COMMENT is like SL_COMMENT but can also take a NEWLINE.
   Pop out of ML_COMMENT state upon scanning of '*#'. Represents end of ML_COMMENT */
<ML_COMMENT>(({SLETTER}|{DIGIT}|{PUNCT}|{SPACE})*)
                              { console.log("Read a line"); return 'ML_COMMENT' }
<ML_COMMENT>{NEWLINE}         { console.log("New Line in multi-line comment"); }
<ML_COMMENT>"*#"              { this.popState(); console.log("End of multiline comment"); return 'EOC'}


/* SWITCH state holds all the possible different Velocity statements user can make */
<SWITCH>"set"                 { this.popState(); return 'SET'}
<SWITCH>"if"                  { this.popState(); return 'IF'}
<SWITCH>"elseif"              { this.popState(); return 'ELSEIF' }
<SWITCH>"else"                { this.popState(); return 'ELSE' }
<SWITCH>"end"                 { this.popState(); return 'END' }
<SWITCH>"foreach"             { this.popState(); return 'FOREACH' }
<SWITCH>"parse"               { this.popState(); return 'PARSE' }
<SWITCH>"break"               { this.popState(); return 'BREAK' }
<SWITCH>"stop"                { this.popState(); return 'STOP' }
<SWITCH>"include"             { this.popState(); return 'INCLUDE' }
<SWITCH>"evaluate"            { this.popState(); return 'EVALUATE' }
<SWITCH>"define"              { this.popState(); return 'DEFINE' }
"."                           return 'PERIOD'
"!"                           return 'EXCLAIM'
"["                           return 'LSQUARE'
"]"                           return 'RSQUARE'
"{"                           return 'LCURLY'
"}"                           return 'RCURLY'
"("                           return 'LPAR'
")"                           return 'RPAR'
{DIGIT}+                      return 'NUMBER'
/*Upon first scan of SINGLEQUOTE or DOUBLEQUOTE in INSTRING state, end string literal */
<INSTRING>"\""                { this.popState(); return 'DOUBLEQUOTE'}
<INSTRING>"'"                 { this.popState(); return 'SINGLEQUOTE'}
<INSTRING>(({SLETTER}|{DIGIT}|{PUNCT}|{SPACE})*)
			      			  return 'STRING'
"in"                          return 'IN'
"and"                         return 'AND'
"eq"                          return 'EQUALTO'
"ne"                          return 'NOTEQUAL'
"lt"                          return 'LESSTHAN'
"gt"                          return 'GREATERTHAN'
"gte"                         return 'GREATERTHANEQUAL'
"lte"                         return 'LESSTHANEQUAL'
"or"                          return 'OR'
<INITIAL,SWITCH>{SLETTER}(({LETTER}|{DIGIT})*)?
			      { this.popState(); return 'ID' }
"+"                           return 'ADD'
"-"                           return 'SUBTRACT'
"*"                           return 'MUL'
"/"                           return 'DIV'
"%"                           return 'IDIV'
"&&"                          return 'AND'
"||"                          return 'OR'
"=="                          return 'EQUALTO'
"!="                          return 'NOTEQUAL'
">"                           return 'GREATERTHAN'
"<"                           return 'LESSTHAN'
">="                          return 'GREATERTHANEQUAL'
"<="                          return 'LESSTHANEQUAL'
"="                           return 'ASSIGN'
":"                           return 'COLON'
"!"                           return 'EXCLAIM'
"["                           return 'LSQUARE'
"]"                           return 'RSQUARE'
"{"                           return 'LCURLY'
"}"                           return 'RCURLY'
"("                           return 'LPAR'
")"                           return 'RPAR'
"@"			                      return 'RATE'
","                           return 'COMMA'
<<EOF>>                       return 'EOF'
%%
/lex

/* operator associations and precedence */

%left '+' '-'
%left '*' '/'
%left '^'
%right '!'
%right '%'
%left UMINUS

%start statements

%% /* language grammar */

/* Velocity code broken up into a list of 'statements' */
statements
    : statement statements
    | EOF
        {
            return symTable;
        }
    ;


/* All the different 'statements' that can be in Velocity code */
statement
    : include_statement
    | parse_statement
    | break_statement
    | stop_statement
    | eval_statement
    | define_statement
    | set_statement
    | if_statement
    | foreach_statement
    | code_statement
    | var
    | single_comment
    | multiline_comment
    ;

/* Any statement that is not recognizable as Velocity is a code statement*/
code_statement
    : ID
    | numeric_dotted
    | string_stmt
    | EXCLAIM
    | HASH
    | DIV
    | ADD
    | SUBTRACT
    | COLON
    | BACKSLASH
    | LESSTHAN
    | GREATERTHAN
    | EQUALTO
    | MUL
    | COMMA
    | RATE
    ;

/* Grammar production rules for numbers that require multiple dots (i.e. IP addresses) */
numeric_dotted
    : NUMBER PERIOD
    | NUMBER
    ;


/* Grammar production rules for Velocity include statements. Allows user to include
   multiple other files and/or variables in their Velocity program
   This production rule only parses the '#include(' statement within the command
*/
include_statement
    : HASH INCLUDE LPAR include_tokens
        {
            console.log("include statement ");
        }
    ;

/* Production rules for the proper syntax of adding variables, files, and both
   to the include command
*/
include_tokens
    : var COMMA include_tokens
    | var RPAR
    | string_stmt COMMA include_tokens
    | string_stmt RPAR
    | RPAR
    ;


/* Grammar production rules for Velocity parse statements. Allows user to parse a single
   variable or file. This production rule only parses the '#parse(' statement within
   a command
 */
parse_statement
    : HASH PARSE LPAR parse_tokens
        {
            //console.log("Parse Statement");
        }
    ;

/* Production rules for the proper syntax of adding either a variable or filename to
 * the parse command
 */
parse_tokens
    : var RPAR
    | string_stmt RPAR
    ;

/* Grammar production rule for break and stop statements in Velocity */
break_statement
    : HASH BREAK
        {
            //console.log("Break Statement");
        }
    ;

stop_statement
    : HASH STOP
        {
            //console.log("STOP Statement");
        }
    ;


/* Grammar production rules for Velocity evaluate statements. Allows user to evaluate variables or strings other in their Velocity program
   This production rule only parses the '#evaluate(' statement within the command */
eval_statement
    : HASH EVALUATE LPAR eval_tokens
        {
            //console.log("Eval Statement");
        }
    ;

/* Production rules for proper syntax of adding a variable to evaluate in the evaluate command */
eval_tokens
    : var RPAR // also implement #evaluate(String)
    ;


/* Grammar production rules for Velocity define statements. Allows user to include a variable to define in their Velocity program
   This production rule only parses the '#define(' statement within the command */
define_statement
    : HASH DEFINE LPAR define_tokens
        {
            //console.log("Define Statement");
        }
    ;

/* Production rules for proper syntax of adding a variable to define in the define command */
define_tokens
    : var RPAR // also implement #define(statement)
    ;


/* Grammar production rules for Velocity set statements. Set statements allow you to assign the value of an arg statement to a variable */
set_statement
    : HASH SET LPAR var ASSIGN arg_statement RPAR
        {
            $$ = $4 + '=' + $6;
            handleAssignment($4, $6);
        }
    ;

/* Grammar production rules for single line and multi line comments */
single_comment
    : HASH COMMENT_START SL_COMMENT
        {
	    	//console.log("Single-line comment" + $3);
        }
    ;

multiline_comment
    : HASH COMMENT_START ML_COMMENT ml_comment_line
        {
	    	//console.log("Grammar: Muliline comment start" + $3);
        }
    ;

ml_comment_line
    : ML_COMMENT ml_comment_line
        {
	    	//console.log("Muliline comment" + $1);
        }
    | EOC
    ;



/* Grammar production rules for argument statements, useful in set statements */
arg_statement
    : object
    | object_list_statement
        {
            var myListInStr = $$;
            $$ = myListInStr.substring(1,myListInStr.length-1).split(",");

        }
    | math_stmt
    | map_stmt
    ;


/* Production rules for a boolean statement made of multiple bool_stmts */
bool_statements
    : bool_stmt logical_operator bool_statements
    | bool_stmt
    ;

logical_operator
    :  AND
    |  OR
    ;


/* Production rules for Velocity IF statements. Works like a standard IF statement: IF boolStmt == true -> do something,
   ELSEIF -> do something else
   ELSE -> do final thing */
if_statement
    : HASH IF LPAR bool_statements RPAR if_end_stmts
    ;

if_end_stmts
    : statement if_end_stmts
    | HASH ELSEIF LPAR bool_statements RPAR elseif_stmts
    | HASH ELSE else_stmts
    | HASH END
    ;


elseif_stmts
    : statement elseif_stmts
    | HASH ELSEIF LPAR bool_statements RPAR elseif_stmts
    | HASH ELSE else_stmts
    | HASH END
    ;


else_stmts
    : statement else_stmts
    | HASH END
    ;

/* Grammar production rules for Velocity FOR loops */
foreach_statement
    : HASH FOREACH LPAR foreach_condition RPAR foreach_end_stmts
        {
            //console.log("foreach loop");
        }
    ;

foreach_end_stmts
    : statement foreach_end_stmts
    | HASH END
    ;


foreach_condition
    : object IN object
        {
            addVariable($1);
            addVariable($3);
            handleAssignment($1, $3);
        }
    | object IN object_list_statement
        {
            addVariable($1);
            addVariable($3);
            handleAssignment($1, $3);
        }
    ;

/* Grammar production rules for Object lists, useful in foreach loops and argument statements
   This production rule provides the proper syntax for identifying a list via parentheses in Velocity*/
object_list_statement
    : LSQUARE list_contents RSQUARE
        {
            $$ = $1 + $2 + $3;
        }
    | LSQUARE RSQUARE
        {
	    	// Looks like an empty statement or null list
            $$ = $1 + $2;        }
    ;


/* Grammar production rule for proper syntax within a list */
list_contents
    : object COMMA list_contents
        {
            //Adding list content
            $$ = $1 + $2 + $3;
        }
    | number_clause PERIOD PERIOD number_clause
        {
        	//Adding list content
            $$ = $1 + $2 + $3 +$4;
        }
    | object
    ;


/* Grammar production rule for an arithmetic statement. Reminder that arithmetic statements are not only
   performed on numbers */
math_stmt
    : object math_operator object
	   {
            $$ = $1 + $2 + $3;
	   }
    ;


/* Different arithmetic operations */
math_operator
    :  ADD
    |  SUBTRACT
    |  MUL
    |  DIV
    |  IDIV
    ;


/* Grammar production rules for Velocity maps, gives proper
   syntax for identifying a map within Velocity code via
   parentheses
*/
map_stmt
    : LCURLY key_value_stmts RCURLY
    ;

/* Proper syntax production rules for adding objects to a map */
key_value_stmts
    : key_value COMMA key_value_stmts
    | key_value
    ;

/* Proper syntax for creating Key-Value pairs that can be added to maps */
key_value
    : object COLON object
    ;

/* Grammar production rules for boolean statements
 */
bool_stmt
    : LPAR bool_stmt RPAR
    | object AND object
        {
            $$ = $1 + $2 + $3;
        }
    | object OR object
        {
            $$ = $1 + $2 + $3;
        }
    | object EQUALTO object
        {
            $$ = $1 + $2 + $3;
        }
    | object NOTEQUAL object
        {
            $$ = $1 + $2 + $3;
        }
    | object GREATERTHAN object
        {
            $$ = $1 + $2 + $3;
        }
    | object LESSTHAN object
        {
            $$ = $1 + $2 + $3;
        }
    | object GREATERTHANEQUAL object
        {
            $$ = $1 + $2 + $3;
        }
    | object LESSTHANEQUAL object
        {
            $$ = $1 + $2 + $3;
        }
    ;


/* Grammar production rules that define the many different data types that can be used
   within Velocity. */
object
    : var
    | string_stmt
    | number_clause
        {
            addNumber($1);
        }
    ;

/* A special production rule within objects to help identify negative numbers
 */
number_clause
    : SUBTRACT NUMBER
         {
			$$ = $1 + $2;
         }
    | NUMBER
    ;

/* Production rules to identify STRING LITERALS
 */
string_stmt
    : SINGLEQUOTE STRING SINGLEQUOTE
        {
            $$ = $2;
            addString($2);
        }
    | DOUBLEQUOTE STRING DOUBLEQUOTE
        {
            $$ = $2;
            addString($2);
        }
    | DOUBLEQUOTE DOUBLEQUOTE
        {
            $$ = $1 + $2;
            addString($$);
        }
    ;



/* Production rules to identify a variable
 */
var
    : VARBEGIN ID
        {
            $$ = $1 + $2;
            addVariable($$);
        }
    | VARBEGIN ID PERIOD ID
        {
            $$ = $1 + $2 + $3 + $4;
            addVariable($$);
        }
    | VARBEGIN ID PERIOD ID LPAR list_contents RPAR
        {
            $$ = $1 + $2 + $3 + $4;
            addVariable($$);
        }
    | VARBEGIN EXCLAIM ID
        {
            $$ = $1 + $3;
            addVariable($$);
        }
    | VARBEGIN LCURLY ID RCURLY
        {
            $$ = $1 + $3;
            addVariable($$);
        }
    | VARBEGIN LCURLY ID PERIOD ID RCURLY
        {
            $$ = $1 + $3 + $4 + $5;
            addVariable($$);
        }
    | VARBEGIN EXCLAIM LCURLY ID RCURLY
        {
            $$ = $1 + $4;
            addVariable($$);
        }
    ;

%%
/*  Simple Attempt at a symbol table, still rudimentary though, ultimate goal
    is to be able to generate a proper syntax tree here
 */
var symTable = new Map();
function addVariable(symbol) {
    if (symTable.get(symbol) == null) {
        symTable.set(symbol, "UNASSIGNED");
    }
}
function addString(ConstString) {
    symTable.set(ConstString, "STRING    ");
}
function addNumber(number) {
    symTable.set(number, "NUMBER    ");
}
function addFile(file) {
    symTable.set(file, "FILE             ");
}
function handleAssignment(symbol, values) {
    // if value is not defined yet then we are assigning undefined to symbol
    // by virtue of that symbol also is undefined
    var allAssigned = true;

    if (Array.isArray(values)) {
        for (vIndex in values) {
            var curVal = symTable.get(values[vIndex]);
            if (curVal == null) {
                //console.log("var being assigned undefined variable");
                allAssigned = false;
                break;
            } else if ( curVal == "UNASSIGNED") {
                allAssigned = false;
                //console.log("var being assigned to another var with no value");
                break;
            }
        }
    } else {
        var curVal = symTable.get(values);
        if (curVal == null) {
            allAssigned = false;
        } else if ( curVal == "UNASSIGNED") {
            allAssigned = false;
        }
    }
    // Mark symbol as assigned value
    if (allAssigned) {
        symTable.set(symbol, "ASSIGNED  ");
    }
}
