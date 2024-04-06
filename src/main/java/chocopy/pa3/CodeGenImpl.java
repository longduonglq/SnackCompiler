package chocopy.pa3;

import java.util.Collections;
import java.util.List;
import java.util.Stack;
import java.util.stream.Collectors;

import chocopy.common.analysis.SymbolTable;
import chocopy.common.analysis.AbstractNodeAnalyzer;
import chocopy.common.analysis.types.ClassValueType;
import chocopy.common.analysis.types.Type;
import chocopy.common.astnodes.*;
import chocopy.common.codegen.*;

import static chocopy.common.codegen.RiscVBackend.Register.*;
import static java.lang.String.format;

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
        this.bke = backend;
    }

    /** Operation on None. */
    private final Label errorNone = new Label("error.None");
    /** Division by zero. */
    private final Label errorDiv = new Label("error.Div");
    /** Index out of bounds. */
    private final Label errorOob = new Label("error.OOB");

    private final boolean _EMIT_RT_TRACE = true;

    protected final RiscVBackend bke;
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

        for (Stmt stmt : statements)
        {
            stmt.dispatch(stmtAnalyzer);
        }
        backend.emitLI(A0, EXIT_ECALL, "Code for ecall: exit");
        backend.emitEcall(null);
    }

    protected String _fnSizeLabel (FuncInfo fi) { return format("@%s.size", fi.getBaseName()); }

    protected void _emitSeparator(String title, String r)
    {
        r = r == null ? "-" : r;
        final int L = 50;
        String sep = new String(new char[L]).replace("\0", r);
        backend.emitInsn( format("#%s( %s )%s", sep, title, sep) , "");
    }

    protected void _rtPrintChar(char c)
    {
        if (_EMIT_RT_TRACE)
        {
            bke.emitADDI(SP, SP, -8, "[debug] reserve space for a0, a1");
            bke.emitSW(A0, SP, +4, "[debug] store old a0");
            bke.emitSW(A1, SP, +0, "[debug] store old a1");

            bke.emitLI(A1, (int) c, "[debug] load character to a1");
            bke.emitLI(A0, PRINT_CHAR_ECALL, "[debug] load character to a1");
            bke.emitEcall("call print_char");

            bke.emitLW(A0, SP, +4, "[debug] restore old a0");
            bke.emitLW(A1, SP, +0, "[debug] restore old a1");
            bke.emitADDI(SP, SP, +8, "[debug] restore sp pointer");
        }
    }

    protected void _rtPrintInt(RiscVBackend.Register reg)
    {
        if (_EMIT_RT_TRACE)
        {
            bke.emitADDI(SP, SP, -8, "[debug] reserve space for a0, a1");
            bke.emitSW(A0, SP, +4, "[debug] store old a0");
            bke.emitSW(A1, SP, +0, "[debug] store old a1");

            bke.emitMV(A1, reg, "[debug] load int to a1");
            bke.emitLI(A0, PRINT_INT_ECALL, "[debug] load character to a1");
            bke.emitEcall("call print_int");

            bke.emitLW(A0, SP, +4, "[debug] restore old a0");
            bke.emitLW(A1, SP, +0, "[debug] restore old a1");
            bke.emitADDI(SP, SP, +8, "[debug] restore sp pointer");
        }
    }

    // runtimePrint
    protected void __rtPrint(String fmt, Object...args)
    {
        if (_EMIT_RT_TRACE)
        {
            Label str = constants.getStrConstant(format(fmt, args));

            // callee
            bke.emitADDI(SP, SP, -8, "[debug] reserve space (old a0, old a1) for stack frame");
            bke.emitSW(A0, SP, +4, "[debug] saves old a0 value");
            bke.emitSW(A1, SP, +0, "[debug] saves old a1 value");

            bke.emitLA(A0, str, "[debug] load str addr to a0");
            bke.emitADDI(A1, A0, 16, "[debug] load addr of attr __str__");
            bke.emitLI(A0, PRINT_STRING_ECALL, "[debug] load ecall for print_string");
            bke.emitEcall("[debug] ecall print_string");

            bke.emitLW(A0, SP, +4, "[debug] restore old a0 value");
            bke.emitLW(A1, SP, +0, "[debug] restore old a1 value");
            bke.emitADDI(SP, SP, +8, "[debug] restore sp ptr");
        }
    }

    protected void _rtPrint(String fmt, Object...args)
    {
        if (_EMIT_RT_TRACE) {
            __rtPrint("[TRACE]: " + fmt, args);
        }
    }
    protected void _rtPrintRegs(RiscVBackend.Register...regs)
    {
        if (_EMIT_RT_TRACE)
        {
            for (RiscVBackend.Register reg : regs)
            {
                _rtPrint("REG[%s] = ", reg.toString());
                _rtPrintInt(reg);
                _rtPrintChar('\n');
            }
        }
    }

    // prints memory region from `ptr` to `ptr + size`, unit of `size` is `word`
    protected void _rtPrintMem(RiscVBackend.Register ptr, int size)
    {
        if (_EMIT_RT_TRACE)
        {
            Label regValueDumpSite = constants.getIntConstant(1984);
            _rtPrint(format("&> MEM region size %d words starting at: ", size));
            _rtPrintRegs(ptr);
            bke.emitADDI(SP, SP, -4, "[debug] space for: old a0 value");
            bke.emitSW(A0, SP, +0, "[debug] saves old a0 value");
            // unroll loop for simple codegen. could be improved. this will generate large assembly for large `size`.
            for (int i = 0; i < size; i++)
            {
                _rtPrint("\tMEM[");
                bke.emitMV(A0, ptr, format("[debug] move reg %s to a0", ptr));
                bke.emitADDI(A0, A0, i * 4, format("[debug] get addr of the %d-th word", i));
                _rtPrintInt(A0);
                __rtPrint("]:= ");

                bke.emitLW(A0, A0, 0, format("[debug] get value of the %d-th word", i));
                _rtPrintInt(A0);
                _rtPrintChar('\n');
                bke.emitLW(A0, SP, +0, "[debug] restore old a0 value");
            }
            bke.emitLW(A0, SP, +0, "[debug] restore old a0 value");
            bke.emitADDI(SP, SP, +4, "[debug] restore sp ptr");
        }
    }

    protected int _getFnArSize(FuncInfo fni)
    {
        // TransientsCount tc = new TransientsCount();
        // Integer maxTempsCount = Collections.max(
        //         fni.getStatements()
        //                 .stream()
        //                 .map(s -> s.dispatch(tc))
        //                 .collect(Collectors.toList()));
        return fni.getLocals().size() * 4
                + 16; // (return addr + control link )
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
    protected void emitUserDefinedFunction(FuncInfo funcInfo)
    {
        _emitSeparator(funcInfo.getFuncName(), null);
        backend.emitGlobalLabel(funcInfo.getCodeLabel());

        // On fn entry, let's adjust `sp` and `fp` as the callee
        int arSize = _getFnArSize(funcInfo);
        // String fnSizeLabel = _fnSizeLabel(funcInfo);
        backend.emitADDI(SP, SP, -arSize, format("[fn=%s] Reserve space for stack frame", funcInfo.getFuncName()));

        backend.emitSW(RA, SP, arSize - 4, format("[fn=%s] Save return address.", funcInfo.getFuncName()));
        backend.emitSW(FP, SP, arSize - 8, format("[fn=%s] Save control link.", funcInfo.getFuncName()));
        backend.emitADDI(FP, SP, arSize, format("[fn=%s] `fp` is at old `sp`.", funcInfo.getFuncName()));

        StmtAnalyzer stmtAnalyzer = new StmtAnalyzer(funcInfo);
        for (Stmt stmt : funcInfo.getStatements())
        {
            stmt.dispatch(stmtAnalyzer);
        }

        // if no explicit final return statement, return None implicitly
        if (!(funcInfo.getStatements().get(funcInfo.getStatements().size() - 1) instanceof ReturnStmt))
        {
            backend.emitMV(A0, ZERO, format("[fn=%s] Returning None implicitly", funcInfo.getFuncName()));
        }

        backend.emitJ(stmtAnalyzer.epilogue, format("[fn=%s] jump to epilogue", funcInfo.getFuncName()));

        backend.emitLocalLabel(stmtAnalyzer.epilogue, "Epilogue");
        backend.emitLW(RA, FP, -4, "get return addr");
        backend.emitLW(FP, FP, -8, "restore callee's fp");
        backend.emitADDI(SP, SP, arSize, "restore stack ptr");
        backend.emitJR(RA, "return to caller");
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
                accMax = Math.max(accMax, ce.args.get(i - 1).dispatch(this) + ce.args.size() - i);
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

        @Override
        public Integer analyze(ReturnStmt rs) { return rs.value.dispatch(this); }

        @Override
        public Integer analyze(ExprStmt es)
        {
            return es.expr.dispatch(this);
        }

        @Override
        public Integer defaultAction(Node n) {
            return Integer.MAX_VALUE;
        }
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

        /**
         * Symbol table for my statements.
         */
        private SymbolTable<SymbolInfo> sym;

        /**
         * Label of code that exits from procedure.
         */
        protected Label epilogue;

        /**
         * The descriptor for the current function, or null at the top
         * level.
         */
        private FuncInfo funcInfo;

        // just here to make sure _pushToStack and _popOffStack calls are balanced.
        private Stack<RiscVBackend.Register> regStack = new Stack<>();

        /**
         * An analyzer for the function described by FUNCINFO0, which is null
         * for the top level.
         */
        StmtAnalyzer(FuncInfo funcInfo0) {
            funcInfo = funcInfo0;
            if (funcInfo == null) {
                sym = globalSymbols;
            } else {
                sym = funcInfo.getSymbolTable();
            }
            epilogue = generateLocalLabel();
        }

        @Override
        public Void analyze(ReturnStmt stmt) {
            // TODO: this assumes that an @f.size constant had been defined. It hasn't been (yet).
            // computes return value
            stmt.value.dispatch(this);
            backend.emitLW(RA, FP, -4, "Get return address");
            backend.emitLW(FP, FP, -8, "Use control link to restore caller's fp");
            backend.emitADDI(SP, SP, _getFnArSize(funcInfo), "Restore stack pointer");
            backend.emitJR(RA, "Return to caller");
            return null;
        }


        @Override
        public Void analyze(IntegerLiteral intLit)
        {
            backend.emitLI(A0, intLit.value, format("Load integer literal: %d", intLit.value));
            // backend.emitJAL(intClass.get);
            return null;
        }

        @Override public Void analyze(StringLiteral strLit)
        {
            Label lbl = constants.getStrConstant(strLit.value);
            backend.emitLA(A0, lbl, format("Load string literal: \"%s\"", strLit.value));
            return null;
        }

        protected Integer _pushRegToStack(RiscVBackend.Register reg, String cmt)
        {
            regStack.push(reg);
            backend.emitADDI(SP, SP, +4, cmt);
            backend.emitSW(reg, SP, 0, format("push reg %s to stack", reg.toString()));
            return null;
        }

        protected Integer _popRegOffStack(RiscVBackend.Register reg, String cmt)
        {
            if (regStack.isEmpty())
                throw new RuntimeException("Unbalanced calls to _pushRegToStack and _popRegOffStack");
            backend.emitLW(reg, SP, 0, format("pop stack to reg %s", reg.toString()));
            backend.emitADDI(SP, SP, -4, cmt);
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
        public Void analyze(ExprStmt es) {
            es.expr.dispatch(this);
            return null;
        }


        // @Override
        // public Void analyze(CallExpr ce)
        // {
        //     // _rtPrint("At CallExpr: %s\n", ce.function.name);
        //     // backend.emitInsn("ebreak", "");
        //     // TODO: static link needs to be dealt with around here (probably)
        //     // backend.emitADDI(SP, FP, format("-%s", _fnSizeLabel(funcInfo)), "");
        //     FuncInfo calleeFnInfo = (FuncInfo) sym.get(ce.function.name);
        //     int fnArSz = _getFnArSize(calleeFnInfo);
        //     backend.emitADDI(SP, FP, -fnArSz, "sp points to top-of-stack");
        //     for (int i = ce.args.size() - 1; 0 <= i; i--)
        //     {
        //         Expr iarg = ce.args.get(i);
        //         iarg.dispatch(this);
        //         _pushRegToStack(A0, format("push arg %d-th of \"%s\" to stack", i, ce.function.name));
        //         // box the argument.
        //     }

        //     FuncInfo finfo = (FuncInfo) sym.get(ce.function.name);
        //     backend.emitJAL(finfo.getCodeLabel(), format("Jump to function %s", finfo.getBaseName()));
        //     return null;
        // }

        @Override
        public Void analyze(CallExpr ce) {
            String functionName = ce.function.name;
            FuncInfo functionInfo = (FuncInfo) sym.get(functionName);
            List<String> functionParams = functionInfo.getParams();
            int fnArSz = _getFnArSize(functionInfo);

            // TODO: Add the appropriate functionality for nested function calls

            for (int i = ce.args.size() - 1; i >= 0; i--) {
                Expr argExpr = ce.args.get(i);
                String paramName = functionParams.get(i);
                StackVarInfo paramInfo = (StackVarInfo) functionInfo.getSymbolTable().get(paramName);

                //Should output result into A0 reg
                argExpr.dispatch(this);

                //Handle "wrapping" integers and booleans
                if (paramInfo.getVarType().equals(Type.OBJECT_TYPE) && argExpr.getInferredType().equals(Type.INT_TYPE)) {
                    // Call Int Wrapping Code Emitter
                    backend.emitInsn("jal wrapInteger", null);
                }

                if (paramInfo.getVarType().equals(Type.OBJECT_TYPE) && argExpr.getInferredType().equals(Type.BOOL_TYPE)) {
                    // Call Bool Wrapping Code Emitter: Create Bool object
                    backend.emitInsn("jal wrapBoolean", null);
                }

                // backend.emitADDI(SP, SP, -1 * backend.getWordSize(), "Move SP to fit arg");
                // backend.emitSW(A0, SP, 0, "Store AO to newly allocated arg space");
                _pushRegToStack(A0, format("push arg %d-th of \"%s\" to stack", i, ce.function.name));
            }

            backend.emitJAL(functionInfo.getCodeLabel(), "Call function: " + functionName);
            backend.emitADDI(SP, FP, -fnArSz, "Set SP to top of stack");
            return null;
        }

        @Override
        public Void analyze(IfStmt ifStmt) {
            Label falseElseBranch = generateLocalLabel();
            Label finishIfStmtBranch = generateLocalLabel();

            ifStmt.condition.dispatch(this);
            backend.emitBEQZ(A0, falseElseBranch, "If A0 == 0, jump to falseElseBranch");

            //TRUE Branch
            for (Stmt thenStmt: ifStmt.thenBody) {
                thenStmt.dispatch(this);
            }
            backend.emitJAL(finishIfStmtBranch, null);

            //FALSE Branch
            backend.emitLocalLabel(falseElseBranch, null);
            for (Stmt elseStmt: ifStmt.elseBody) {
                elseStmt.dispatch(this);
            }

            backend.emitLocalLabel(finishIfStmtBranch, null);
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
        emitWrappedInt();
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

    private void emitWrappedInt() {
        Label emitWrappedIntLabel = new Label("wrapInteger");
        ClassInfo intClassInfo = (ClassInfo) globalSymbols.get("int");
        Label intClassPrototypeLabel = intClassInfo.getPrototypeLabel();

        backend.emitGlobalLabel(emitWrappedIntLabel);
        backend.emitADDI(SP, SP, -8, null);
        backend.emitSW(RA, SP, 0, null);
        backend.emitSW(A0, SP, 4, null);
        backend.emitLA(A0, intClassPrototypeLabel, null);
        backend.emitInsn("jal alloc", null);
        backend.emitLW(T0, SP, 4, null);
        backend.emitSW(T0, A0, getAttrOffset(intClass, "__int__"), null);
        backend.emitLW(RA, SP, 0, null);
        backend.emitADDI(SP, SP, 8, null);
        backend.emitJR(RA, null);
    }
}
