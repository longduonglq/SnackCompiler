package chocopy.pa3;

import java.util.List;
import java.util.Stack;

import chocopy.common.analysis.SymbolTable;
import chocopy.common.analysis.AbstractNodeAnalyzer;
import chocopy.common.analysis.types.Type;
import chocopy.common.astnodes.*;
import chocopy.common.codegen.*;

import static chocopy.common.codegen.RiscVBackend.Register.*;

/**
 * This is where the main implementation of PA3 will live.
 *
 * A large part of the functionality has already been implemented
 * in the base class, CodeGenBase. Make sure to read through that
 * class, since you will want to use many of its fields
 * and utility methods in this class when emitting code.
 *
 * Also read the PDF spec for details on what the base class does and
 * what APIs it exposes for its sub-class (this one). Of particular
 * importance is knowing what all the SymbolInfo classes contain.
 */
public class CodeGenImpl extends CodeGenBase {

    /** A code generator emitting instructions to BACKEND. */
    public CodeGenImpl(RiscVBackend backend) {
        super(backend);
    }

    /** Operation on None. */
    private final Label errorNone = new Label("error.None");
    /** Division by zero. */
    private final Label errorDiv = new Label("error.Div");
    /** Index out of bounds. */
    private final Label errorOob = new Label("error.OOB");

    /**
     * Emits the top level of the program.
     *
     * This method is invoked exactly once, and is surrounded
     * by some boilerplate code that: (1) initializes the heap
     * before the top-level begins and (2) exits after the top-level
     * ends.
     *
     * You only need to generate code for statements.
     *
     * @param statements top level statements
     */
    protected void emitTopLevel(List<Stmt> statements) {
        StmtAnalyzer stmtAnalyzer = new StmtAnalyzer(null);
        backend.emitADDI(SP, SP, -2 * backend.getWordSize(),
                         "Saved FP and saved RA (unused at top level).");
        backend.emitSW(ZERO, SP, 0, "Top saved FP is 0.");
        backend.emitSW(ZERO, SP, 4, "Top saved RA is 0.");
        backend.emitADDI(FP, SP, 2 * backend.getWordSize(),
                         "Set FP to previous SP.");

        for (Stmt stmt : statements) {
            stmt.dispatch(stmtAnalyzer);
        }
        backend.emitLI(A0, EXIT_ECALL, "Code for ecall: exit");
        backend.emitEcall(null);
    }

    /**
     * Emits the code for a function described by FUNCINFO.
     *
     * This method is invoked once per function and method definition.
     * At the code generation stage, nested functions are emitted as
     * separate functions of their own. So if function `bar` is nested within
     * function `foo`, you only emit `foo`'s code for `foo` and only emit
     * `bar`'s code for `bar`.
     */
    protected void emitUserDefinedFunction(FuncInfo funcInfo) {
        backend.emitGlobalLabel(funcInfo.getCodeLabel());
        StmtAnalyzer stmtAnalyzer = new StmtAnalyzer(funcInfo);

        for (Stmt stmt : funcInfo.getStatements())
        {
            stmt.dispatch(stmtAnalyzer);
        }

        // if no explicit final return statement, return None implicitly
        if (!(funcInfo.getStatements().get(funcInfo.getStatements().size() - 1) instanceof ReturnStmt))
        {
            backend.emitMV(A0, ZERO, "Returning None implicitly");
        }
        backend.emitLocalLabel(stmtAnalyzer.epilogue, "Epilogue");

        // FIXME: {... reset fp etc. ...}
    }

    static private class TransientsCount extends AbstractNodeAnalyzer< Integer >
    {
        @Override
        public Integer analyze(BinaryExpr be)
        {
            Integer l = be.left.dispatch(this);
            Integer r = be.right.dispatch(this);
            return Math.max(l, 1 + r);
        }

        @Override
        public Integer analyze(IfExpr ie)
        {
            Integer condExpr = ie.condition.dispatch(this);
            Integer thenExpr = ie.thenExpr.dispatch(this);
            Integer elseExpr = ie.elseExpr.dispatch(this);
            return Math.max(condExpr, Math.max(thenExpr, elseExpr));
        }

        @Override
        public Integer analyze(CallExpr ce)
        {
            int accMax = 0;
            for (int i = 1; i <= ce.args.size(); i++)
                accMax = Math.max(accMax, ce.dispatch(this) + ce.args.size() - i);
            return accMax;
        }
        @Override
        public Integer analyze(MethodCallExpr mce)
        {
            int accMax = 0;
            for (int i = 1; i <= mce.args.size(); i++)
                accMax = Math.max(accMax, mce.dispatch(this) + mce.args.size() - i);
            return accMax;
        }

        // @Override public Integer defaultAction(Node node) { return 0; }
        @Override public Integer analyze(BooleanLiteral lit) { return 0; }
        @Override public Integer analyze(StringLiteral lit) { return 0; }
        @Override public Integer analyze(IntegerLiteral lit) { return 0; }
        @Override public Integer analyze(NoneLiteral lit) { return 0; }
    }


    /** An analyzer that encapsulates code generation for statments. */
    private class StmtAnalyzer extends AbstractNodeAnalyzer<Void> {
        /*
         * The symbol table has all the info you need to determine
         * what a given identifier 'x' in the current scope is. You can
         * use it as follows:
         *   SymbolInfo x = sym.get("x");
         *
         * A SymbolInfo can be one the following:
         * - ClassInfo: a descriptor for classes
         * - FuncInfo: a descriptor for functions/methods
         * - AttrInfo: a descriptor for attributes
         * - GlobalVarInfo: a descriptor for global variables
         * - StackVarInfo: a descriptor for variables allocated on the stack,
         *      such as locals and parameters
         *
         * Since the input program is assumed to be semantically
         * valid and well-typed at this stage, you can always assume that
         * the symbol table contains valid information. For example, in
         * an expression `foo()` you KNOW that sym.get("foo") will either be
         * a FuncInfo or ClassInfo, but not any of the other infos
         * and never null.
         *
         * The symbol table in funcInfo has already been populated in
         * the base class: CodeGenBase. You do not need to add anything to
         * the symbol table. Simply query it with an identifier name to
         * get a descriptor for a function, class, variable, etc.
         *
         * The symbol table also maps nonlocal and global vars, so you
         * only need to lookup one symbol table and it will fetch the
         * appropriate info for the var that is currently in scope.
         */

        /** Symbol table for my statements. */
        private SymbolTable<SymbolInfo> sym;

        /** Label of code that exits from procedure. */
        protected Label epilogue;

        /** The descriptor for the current function, or null at the top
         *  level. */
        private FuncInfo funcInfo;

        // TODO: some indication of where temporaries should continue
        // this represents offsets from `fp`.
        protected Stack<Integer> tempsOffsetStack = new Stack<>();

        /** An analyzer for the function described by FUNCINFO0, which is null
         *  for the top level. */
        StmtAnalyzer(FuncInfo funcInfo0) {
            funcInfo = funcInfo0;
            if (funcInfo == null) {
                sym = globalSymbols;
            } else {
                sym = funcInfo.getSymbolTable();
            }
            epilogue = generateLocalLabel();
            tempsOffsetStack.push(0);
        }

        @Override
        public Void analyze(ReturnStmt stmt) {
            // TODO: this assumes that an @f.size constant had been defined. It hasn't been (yet).
            // computes return value
            stmt.value.dispatch(this);
            backend.emitLW(RA, FP, -4, "Get return address");
            backend.emitLW(FP, FP, -8, "Use control link to restore caller's fp");
            backend.emitADDI(SP, SP, String.format("@%s.size", funcInfo.getBaseName()), "Restore stack pointer");
            backend.emitJR(RA, "Return to caller");
            return null;
        }

        @Override
        public Void analyze(AssignStmt as)
        {
            as.value.dispatch(this);
            return null;
        }

        protected Integer _pushTempToStack(RiscVBackend.Register reg, String cmt)
        {
            backend.emitSW(reg, FP, -tempsOffsetStack.peek(),
                    cmt != null ? cmt : String.format("Store temporary in %s to stack", reg.toString()));
            tempsOffsetStack.push(tempsOffsetStack.peek() + 4);
            return tempsOffsetStack.peek();
        }
        protected Integer _popTempOffStack(RiscVBackend.Register reg, String cmt)
        {
            tempsOffsetStack.pop();
            backend.emitLW(reg, FP, -tempsOffsetStack.peek(),
                    cmt != null ? cmt : String.format("Pop temporary from stack to reg %s", reg.toString()));
            return tempsOffsetStack.peek();
        }

        @Override
        public Void analyze(BinaryExpr be)
        {
            be.left.dispatch(this);
            _pushTempToStack(A0, "Store binop's left operand to stack");
            be.right.dispatch(this);
            _popTempOffStack(T1, "Binop's left operand from stack to `T1`.");
            switch (be.operator)
            {
                case "+":
                    backend.emitADD(A0, T1, A0, "+ two operands");
                    break;
                case "-":
                    backend.emitSUB(A0, T1, A0, "- two operands");
                    break;
                case "*":
                    backend.emitMUL(A0, T1, A0, "* two operands");
                    break;
                case "//":
                    backend.emitDIV(A0, T1, A0, "// two operands");
                    break;
                case "%":
                    backend.emitREM(A0, T1, A0, "% two operands");
                    break;
            }
            return null;
        }

        @Override
        public Void analyze(BooleanLiteral bl) {
            //Store boolean in A0 reg?
            //Booleans - True: 1 and False: 0
            backend.emitLI(A0, bl.value ? 1 : 0, "Load boolean immediate val into A0");
            return null;
        }

        @Override
        public Void analyze(StringLiteral sl) {
            Label stringLabel = constants.getStrConstant(sl.value);
            backend.emitLA(A0, stringLabel, "Load string label to A0");
            return null;
        }

        @Override
        public Void analyze(ExprStmt es) {
            es.expr.dispatch(this);
            return null;
        }

        @Override
        public Void analyze(CallExpr ce) {
            String functionName = ce.function.name;
            FuncInfo functionInfo = (FuncInfo) sym.get(functionName);
            List<String> functionParams = functionInfo.getParams();

            //TODO: Add the appropriate functionality for nested function calls

            for (int i = ce.args.size() - 1; i >= 0; i--) {
                Expr argExpr = ce.args.get(i);
                String paramName = functionParams.get(i);
                StackVarInfo paramInfo = (StackVarInfo) functionInfo.getSymbolTable().get(paramName);

                //Should output result into A0 reg
                argExpr.dispatch(this);

                //Handle "wrapping" integers and booleans
                if (paramInfo.getVarType().equals(Type.OBJECT_TYPE) && argExpr.getInferredType().equals(Type.INT_TYPE)) {
                    //Call Int Wrapping Code Emitter
                    backend.emitInsn("jal wrapInteger", null);
                }

                if (paramInfo.getVarType().equals(Type.OBJECT_TYPE) && argExpr.getInferredType().equals(Type.BOOL_TYPE)) {
                    //Call Bool Wrapping Code Emitter: Create Bool object
                    backend.emitInsn("jal wrapBoolean", null);
                }

                backend.emitADDI(SP, SP, -1 * backend.getWordSize(), "Move SP to fit arg");
                backend.emitSW(A0, SP, 0, "Store AO to newly allocated arg space");
            }

            backend.emitJAL(functionInfo.getCodeLabel(), "Call function: " + functionName);
            return null;
        }
    }

    /**
     * Emits custom code in the CODE segment.
     *
     * This method is called after emitting the top level and the
     * function bodies for each function.
     *
     * You can use this method to emit anything you want outside of the
     * top level or functions, e.g. custom routines that you may want to
     * call from within your code to do common tasks. This is not strictly
     * needed. You might not modify this at all and still complete
     * the assignment.
     *
     * To start you off, here is an implementation of three routines that
     * will be commonly needed from within the code you will generate
     * for statements.
     *
     * The routines are error handlers for operations on None, index out
     * of bounds, and division by zero. They never return to their caller.
     * Just jump to one of these routines to throw an error and
     * exit the program. For example, to throw an OOB error:
     *   backend.emitJ(errorOob, "Go to out-of-bounds error and abort");
     *
     */
    protected void emitCustomCode() {
        emitErrorFunc(errorNone, "Operation on None");
        emitErrorFunc(errorDiv, "Division by zero");
        emitErrorFunc(errorOob, "Index out of bounds");
        emitWrappedBoolean();
    }

    /** Emit an error routine labeled ERRLABEL that aborts with message MSG. */
    private void emitErrorFunc(Label errLabel, String msg) {
        backend.emitGlobalLabel(errLabel);
        backend.emitLI(A0, ERROR_NONE, "Exit code for: " + msg);
        backend.emitLA(A1, constants.getStrConstant(msg),
                       "Load error message as str");
        backend.emitADDI(A1, A1, getAttrOffset(strClass, "__str__"),
                         "Load address of attribute __str__");
        backend.emitJ(abortLabel, "Abort");
    }

    private void emitWrappedBoolean() {
        Label emitWrappedBooleanLabel = new Label("wrapBoolean");
        Label localTrueBranchLabel = generateLocalLabel();

        backend.emitGlobalLabel(emitWrappedBooleanLabel);
        backend.emitLI(T0, 1, "Load True into temp reg for comparison");
        backend.emitBEQ(A0, T0, localTrueBranchLabel, "Check which boolean branch to go to");
        //False
        backend.emitLA(A0, constants.getBoolConstant(false), "Load False constant's address into A0");
        backend.emitJR(RA, "Go back");
        //True
        backend.emitLocalLabel(localTrueBranchLabel, "Label for true branch");
        backend.emitLA(A0, constants.getBoolConstant(true), "Load True constant's address into A0");
        backend.emitJR(RA, "Go back");
    }

    private void emitWrappedInt(int value) {
        Label emitWrappedIntLabel = new Label("wrapInteger");

        backend.emitGlobalLabel(emitWrappedIntLabel);
        backend.emitLA(A0, constants.getIntConstant(value), "Load Int constant's address into A0");
        backend.emitJR(RA, "Go back");
    }
}
