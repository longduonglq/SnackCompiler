package chocopy.pa3;

import java.util.*;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.AbstractMap.SimpleEntry;

import chocopy.common.analysis.SymbolTable;
import chocopy.common.analysis.AbstractNodeAnalyzer;
import chocopy.common.analysis.types.ClassValueType;
import chocopy.common.analysis.types.FuncType;
import chocopy.common.analysis.types.Type;
import chocopy.common.analysis.types.ValueType;
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

    /**
     * A code generator emitting instructions to BACKEND.
     */
    public CodeGenImpl(RiscVBackend backend) {
        super(backend);
        this.bke = backend;
        bke.defineSym("@boolTRUE", "const_1");
        bke.defineSym("@boolFALSE", "const_0");
        // bke.defineSym("@listHeaderSize", "4");
    }

    /**
     * Operation on None.
     */
    // private final Label errorNone = new Label("error.None");
    private final Label errorNone = new Label("errNONE");
    /**
     * Division by zero.
     */
    // private final Label errorDiv = new Label("error.Div");
    private final Label errorDiv = new Label("errDIV");
    /**
     * Index out of bounds.
     */
    // private final Label errorOob = new Label("error.OOB");
    private final Label errorOob = new Label("errOOB");

    private final boolean _EMIT_RT_TRACE = true;
    private final Label consListLabel = new Label("constructList");
    private final Label concatListLabel = new Label("concatenateList");
    private final Label createCharTable = new Label("createSmallCharTable");
    private final Label charTable = new Label("smallCharsTable");
    private final Label strEql = new Label("strEql");

    protected final RiscVBackend bke;

    /**
     * Emits the top level of the program.
     * <p>
     * This method is invoked exactly once, and is surrounded
     * by some boilerplate code that: (1) initializes the heap
     * before the top-level begins and (2) exits after the top-level
     * ends.
     * <p>
     * You only need to generate code for statements.
     *
     * @param statements top level statements
     */
    protected void emitTopLevel(List<Stmt> statements)
    {
        StmtAnalyzer stmtAnalyzer = new StmtAnalyzer(null);
        int mainArSz = _getFnArSize(
                new FuncInfo(
                        "main", 0,
                        Type.NONE_TYPE, null, null, null));
        backend.emitADDI(SP, SP, -mainArSz * backend.getWordSize(),
                "Saved FP and saved RA (unused at top level).");
        backend.emitSW(RA, SP, mainArSz - 4, format("[fn=%s] Save return address.", "main"));
        backend.emitSW(FP, SP, mainArSz - 8, format("[fn=%s] Save control link.", "main"));
        backend.emitSW(ZERO, SP, 0, "Top saved FP is 0.");
        backend.emitSW(ZERO, SP, 4, "Top saved RA is 0.");
        backend.emitADDI(FP, SP, mainArSz * backend.getWordSize(),
                "Set FP to previous SP.");

        backend.emitJAL(createCharTable, "create one-character string table");

        for (Stmt stmt : statements)
        {
            stmt.dispatch(stmtAnalyzer);
        }
        backend.emitLI(A0, EXIT_ECALL, "Code for ecall: exit");
        backend.emitEcall(null);
    }

    protected void _emitSeparator(String title, String r) {
        r = r == null ? "-" : r;
        final int L = 50;
        String sep = new String(new char[L]).replace("\0", r);
        backend.emitInsn(format("#%s( %s )%s", sep, title, sep), "");
    }

    /**
     * Ideally, we should actually calculate the number of temporaries needed but for now,
     * let's take advantage of the fact that most functions in test suite doesn't need a lot of
     * tmps for each function call.
     * */
    protected int _getFnTempsCount(FuncInfo fni)
    {
        // TransientsCount tc = new TransientsCount();
        // Integer maxTempsCount = Collections.max(
        //         fni.getStatements()
        //                 .stream()
        //                 .map(s -> s.dispatch(tc))
        //                 .collect(Collectors.toList()));
        // return maxTempsCount;
        return 12;
    }

    protected int _getFnArSize(FuncInfo fni)
    {
        return fni.getLocals().size() * 4
                + 8 // (return addr + control link )
                + _getFnTempsCount(fni) * 4
                ;
    }

    public static String escape(String s)
    {
        return s.replace("\n", "\\n");
    }

    /**
     * Emits the code for a function described by FUNCINFO.
     * <p>
     * This method is invoked once per function and method definition.
     * At the code generation stage, nested functions are emitted as
     * separate functions of their own. So if function `bar` is nested within
     * function `foo`, you only emit `foo`'s code for `foo` and only emit
     * `bar`'s code for `bar`.
     */
    protected void emitUserDefinedFunction(FuncInfo funcInfo) {
        _emitSeparator(funcInfo.getFuncName(), null);
        backend.emitGlobalLabel(funcInfo.getCodeLabel());
        // _rtPrint("In func %s\n", funcInfo.getFuncName());
        // _rtPrintRegs(RA, FP, SP);

        // On fn entry, let's adjust `sp` and `fp` as the callee
        int arSize = _getFnArSize(funcInfo);
        // String fnSizeLabel = _fnSizeLabel(funcInfo);
        backend.emitADDI(SP, SP, -arSize, format("[fn=%s] Reserve space for stack frame", funcInfo.getFuncName()));

        backend.emitSW(RA, SP, arSize - 4, format("[fn=%s] Save return address.", funcInfo.getFuncName()));
        backend.emitSW(FP, SP, arSize - 8, format("[fn=%s] Save control link.", funcInfo.getFuncName()));
        backend.emitADDI(FP, SP, arSize, format("[fn=%s] `fp` is at old `sp`.", funcInfo.getFuncName()));

        StmtAnalyzer stmtAnalyzer = new StmtAnalyzer(funcInfo);
        // let's first process locally-init variables
        for (StackVarInfo svi : funcInfo.getLocals()) {
            // int idx = funcInfo.getVarIndex(svi.getVarName());
            if (svi.getVarType().isSpecialType())
            {
                svi.getInitialValue().dispatch(stmtAnalyzer);
                stmtAnalyzer.pushRegToLocalVar(A0, svi);
            }
            else if (svi.getInitialValue() instanceof NoneLiteral)
            {
                stmtAnalyzer.pushRegToLocalVar(ZERO, svi);
            }
        }

        for (Stmt stmt : funcInfo.getStatements()) {
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
        backend.emitLW(FP, FP, -8, "Use control link to restore caller's fp");
        backend.emitADDI(SP, SP, _getFnArSize(funcInfo), "restore stack ptr");
        backend.emitJR(RA, "return to caller");
    }

    static private class TransientsCount extends AbstractNodeAnalyzer<Integer> {
        @Override
        public Integer analyze(BinaryExpr be) {
            Integer l = be.left.dispatch(this);
            Integer r = be.right.dispatch(this);
            return Math.max(l, 1 + r);
        }

        @Override
        public Integer analyze(IfExpr ie) {
            Integer condExpr = ie.condition.dispatch(this);
            Integer thenExpr = ie.thenExpr.dispatch(this);
            Integer elseExpr = ie.elseExpr.dispatch(this);
            return Math.max(condExpr, Math.max(thenExpr, elseExpr));
        }

        @Override
        public Integer analyze(CallExpr ce) {
            int accMax = 0;
            for (int i = 1; i <= ce.args.size(); i++)
                accMax = Math.max(accMax, ce.args.get(i - 1).dispatch(this) + ce.args.size() - i);
            return accMax;
        }

        @Override
        public Integer analyze(MethodCallExpr mce) {
            int accMax = 0;
            for (int i = 1; i <= mce.args.size(); i++)
                accMax = Math.max(accMax, mce.dispatch(this) + mce.args.size() - i);
            return accMax;
        }

        @Override
        public Integer analyze(ReturnStmt rs) {
            return rs.value.dispatch(this);
        }

        @Override
        public Integer analyze(ExprStmt es) {
            return es.expr.dispatch(this);
        }

        @Override
        public Integer defaultAction(Node n) {
            return Integer.MAX_VALUE;
        }
    }
    @FunctionalInterface
    protected interface Func3<A, B, C, D>
    {
        D apply(A a, B b, C c);
    }

    @FunctionalInterface
    protected interface Func4<A, B, C, D, E>
    {
        E apply(A a, B b, C c, D d);
    }
    @FunctionalInterface
    protected interface Func5<A, B, C, D, E, F>
    {
        F apply(A a, B b, C c, D d, E e);
    }

    // set of functions that would be useful both inside and outside of StmtAnalyzer
    /**
     * For the following functions, please refer to the stack diagram in chocopy_impl_guide.
     * Basically, I assumed the following layout for a function AR:
     *          1. temporaries          <-- SP
     *          2. locals
     *          3. control link
     *          4. return addr          <-- FP
     *
     *  Instead of generating code to adjust SP each time a temporary is added,
     *  we (as the compiler) simply remember which temporary locations (in the fixed-sized
     *      memory region reserved for temporaries) had been occupied.
     *  More specifically, we remember this information by keep track of `curTemp`, which points to
     *      the offset (counted from the last locals) of the available space for a new temporary.
     *  `curTemp` ranges from [1...MAX_TEMP_COUNT]
     *
     *  Example:: When `curTemp` is one, there are no temporaries.
     *
     *  Functions in AsmHelper are meant to abstract away all of this.
     *  There are examples of how to use these functions in the code.
     *  Note that since AsmHelper's function are stateless, we need to update the states manually
     *      (For example: look at part of the code looking like this `curTemp = AsmHelper.fn(...)` to see what i mean)
     *
     *  @@@ If you happen to be working in StmtAnalyzer, you might want to use the wrapper for these
     *      methods in StmtAnalyzer for ease.
     *
     *
     * @@@ -- Regarding shrinkStack, inflateStack operation ---
     * Recall that the top of the stack are temporaries. Sometimes, we'd like to invoke a callee
     *      whose arguments have been put in the caller's temporaries. Since the callee always
     *      looks for its argument by dereferencing a positive offset from FP, we simply adjust SP
     *      (shrink the top of our stack/shrink our AR frame) such that when the callee is invoked, it will
     *      find its locals at a positive offset from FP (which happens to be where the caller put the args
     *      in the temporaries section).
     *
     *
     * There are functions to pushTemporary and popTemporary. pushTemporary returns a `token`, ie a number
     *  that sort of references the location of pushed temporary on the stack. This way, you can retrieve
     *  the temporary (without popping it) by calling loadTemp...()
     * */
    static protected class AsmHelper
    {
        static public int initTemps(RiscVBackend backend, int MAX_TEMP_COUNT)
        {
            return clearTemps(backend, MAX_TEMP_COUNT);
        }

        // assume stack is full-sized
        static public int shrinkTopStackTo(
                RiscVBackend backend,
                int MAX_TEMP_COUNT, int curTemp, String cmnt)
        {
            int wsz = backend.getWordSize();
            backend.emitADDI(SP, SP,
                    // +MAX_TEMP_COUNT * wsz - (curTemp - 1) * wsz,
                    +(MAX_TEMP_COUNT - (curTemp - 1)) * wsz,
                    cmnt);
            return curTemp;
        }

        static public int inflateStack(
                RiscVBackend backend,
                int MAX_TEMP_COUNT, int curTemp, String cmnt)
        {
            int wsz = backend.getWordSize();
            backend.emitADDI(SP, SP,
                    -(MAX_TEMP_COUNT - (curTemp - 1)) * wsz,
                    cmnt);
            return curTemp;
        }

        static public int pushTempTopStackAligned(
                RiscVBackend backend,
                RiscVBackend.Register reg, int MAX_TEMP_COUNT, int curTemp,
                String cmnt)
        {
            if (curTemp > MAX_TEMP_COUNT)
                throw new IllegalArgumentException("temp space full");
            backend.emitSW(reg, SP,
                    (curTemp++ -1) * backend.getWordSize(),
                    cmnt);
            return curTemp;
        }

        static public SimpleEntry<
                        Integer, //updated curTemp
                        List< SimpleEntry<RiscVBackend.Register, Integer> > >
            backupRegistersToTemp(
                RiscVBackend bke,
                int MAX_TEMP_COUNT, int curTemp,
                String cmnt,
                RiscVBackend.Register...regs)
        {
            List< SimpleEntry<RiscVBackend.Register, Integer> > token = new ArrayList<>();
            for (RiscVBackend.Register r : regs)
            {
                token.add(new SimpleEntry<>(r, curTemp));
                curTemp = AsmHelper.pushTemp(bke, r, MAX_TEMP_COUNT, curTemp, cmnt);
            }
            return new SimpleEntry<>(curTemp, token);
        }

        static public int
            restoreRegisters(
                    RiscVBackend bke,
                    int MAX_TEMP_COUNT, int curTemp,
                    String cmnt,
                    List< SimpleEntry<RiscVBackend.Register, Integer> > token)
        {
            // restore in reverse order
            for (int i = token.size() - 1; i >= 0; i--)
            {
                SimpleEntry< RiscVBackend.Register, Integer > regInt = token.get(i);
                if (curTemp - 1 != regInt.getValue())
                    throw new RuntimeException(
                            format("[restoring reg] slot for reg %s is not at top of stack", regInt.getKey()));
                curTemp = popTempToReg(bke, regInt.getKey(), MAX_TEMP_COUNT, curTemp, cmnt);
            }
            return curTemp;
        }

        static public int pushTemp(
                RiscVBackend backend,
                RiscVBackend.Register reg, int MAX_TEMP_COUNT, int curTemp,
                // int fnArSz,
                String cmnt)
        {
            // curTemp : [1...MAX_TEMP_COUNT+1]
            if (curTemp > MAX_TEMP_COUNT)
                throw new IllegalArgumentException("temp space full");
            backend.emitSW(reg, SP,
                    (MAX_TEMP_COUNT - curTemp++) * backend.getWordSize(),
                    cmnt);
            return curTemp;
        }

        static public void loadTempToReg(
                RiscVBackend backend,
                RiscVBackend.Register reg, int MAX_TEMP_COUNT, int temp,
                String cmnt)
        {
            // curTemp : [1...MAX_TEMP_COUNT+1]
            if (temp < 1)
                throw new IllegalArgumentException("temp space empty");
            backend.emitLW(reg, SP,
                    (MAX_TEMP_COUNT - temp) * backend.getWordSize(),
                    cmnt);
        }

        static public void storeTempFromReg(
                RiscVBackend backend,
                RiscVBackend.Register reg, int MAX_TEMP_COUNT, int temp,
                String cmnt)
        {
            // curTemp : [1...MAX_TEMP_COUNT+1]
            if (temp < 1)
                throw new IllegalArgumentException("temp space empty");
            backend.emitSW(reg, SP,
                    (MAX_TEMP_COUNT - temp) * backend.getWordSize(),
                    cmnt);
        }

        static public int clearTemps(RiscVBackend backend, int MAX_TEMP_COUNT)
        {
            return 1;
        }

        static public int popTempToReg(
                RiscVBackend backend,
                RiscVBackend.Register reg, int MAX_TEMP_COUNT, int curTemp,
                // int fnArSz,
                String cmnt)
        {
            if (curTemp <= 1)
                throw new IllegalArgumentException("nothing to pop");
            // backend.emitLW(reg, SP, (MAX_TEMP_COUNT - --curTemp) * backend.getWordSize(), cmnt);
            backend.emitLW(reg, SP,
                    (MAX_TEMP_COUNT - --curTemp) * backend.getWordSize(),
                    // -(fnArSz - MAX_TEMP_COUNT * backend.getWordSize()) - (--curTemp) * backend.getWordSize(),
                    cmnt);
            return curTemp;
        }

        static public Void pushRegToLocalVar(
                RiscVBackend backend,
                FuncInfo fn, int varIdx,
                RiscVBackend.Register fp, RiscVBackend.Register dest,
                String cmt)
        {
            return _accessRegToVar(backend, fn, varIdx, fp, dest, cmt,
                    (bke, r1, r2, offset, cmnt) -> {
                        bke.emitSW(r1, r2, offset, cmnt);
                        return null;
                    });
        }

        static public Void loadLocalVarToReg(
                RiscVBackend backend,
                FuncInfo fn, int varIdx,
                RiscVBackend.Register fp, RiscVBackend.Register dest,
                String cmt)
        {
            return _accessRegToVar(backend, fn, varIdx, fp, dest, cmt,
                    (bke, r1, r2, offset, cmnt) -> {
                        bke.emitLW(r1, r2, offset, cmnt);
                        return null;
                    });
        }

        // varIdx could be -1 to indicate trying to load a static link
        static protected Void _accessRegToVar(
                RiscVBackend backend,
                FuncInfo fn, int varIdx,
                RiscVBackend.Register fp, RiscVBackend.Register dest,
                String cmt,
                Func5<RiscVBackend, RiscVBackend.Register, RiscVBackend.Register, Integer, String, Void> op
                // op(backend, destination, fp, offset from fp, cmnt);
        )
        {
            int maxParamIndex = fn.getParams().size() - 1;
            int maxLocalIndex = fn.getLocals().size() + fn.getParams().size() + 2 - 1;
            VarInfo vi = null;
            int offsetFromFP;
            if (varIdx <= maxParamIndex) // is param
            {
                offsetFromFP = maxParamIndex - varIdx;
                if (varIdx == -1 && fn.getParentFuncInfo() == null)
                    throw new IllegalArgumentException("trying to get static link but function not nested");
                op.apply(backend, dest, fp, +offsetFromFP * backend.getWordSize(), cmt);
            } else if (maxParamIndex + 2 < varIdx && varIdx <= maxLocalIndex) // is local
            {
                offsetFromFP = varIdx - fn.getParams().size();
                op.apply(backend, dest, fp, -offsetFromFP * backend.getWordSize() - 4, cmt);
            } else throw new IllegalArgumentException("should be unreachable");

            return null;
        }
    }

    /**
     * An analyzer that encapsulates code generation for statments.
     */
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

        private final int MAX_TEMPS;
        private int curTemp;
        private Stack<String> tempContent = new Stack<>();

        private Stack<
                    SimpleEntry<
                            FuncInfo,
                            Set< RiscVBackend.Register >>>
                fn2RegistersInUse = new Stack<>();

        public void _enterNewRegisterSpace(FuncInfo fn)
        {
            fn2RegistersInUse.push(new SimpleEntry<>(fn, new HashSet<>()));
        }
        public void _exitRegisterSpace(FuncInfo fn) {
            FuncInfo poppedFn = fn2RegistersInUse.pop().getKey();
            if (!poppedFn.equals(fn))
            {
                throw new RegisterNotFreeException("poppedFn != fn");
            }
        }
        public void _claimRegister(RiscVBackend.Register reg) {
            FuncInfo topFn = fn2RegistersInUse.peek().getKey();
            Set<RiscVBackend.Register> topFnRegInUse = fn2RegistersInUse.peek().getValue();
            if (topFnRegInUse.contains(reg))
            {
                throw new RegisterNotFreeException(format("trying to claim register %s which is already claimed", reg.toString()));
            }
            topFnRegInUse.add(reg);
        }
        public void _ClaimRegisters(RiscVBackend.Register ...regs) {
            for (RiscVBackend.Register r : regs)
            {
                _claimRegister(r);
            }
        }
        public void _AssertRegistersFree(RiscVBackend.Register ...regs)  {
            FuncInfo topFn = fn2RegistersInUse.peek().getKey();
            Set<RiscVBackend.Register> topFnRegInUse = fn2RegistersInUse.peek().getValue();
            for (RiscVBackend.Register r : regs)
            {
                if (topFnRegInUse.contains(r))
                {
                    throw new RegisterNotFreeException(format("Register %s is NOT free", r.toString()));
                }
            }
        }
        public void _returnRegister(RiscVBackend.Register reg)
        {
            FuncInfo topFn = fn2RegistersInUse.peek().getKey();
            Set<RiscVBackend.Register> topFnRegInUse = fn2RegistersInUse.peek().getValue();
            if (!topFnRegInUse.contains(reg))
            {
                throw new RegisterNotFreeException(format("trying to return register %s which has NOT been claimed", reg.toString()));
            }
            topFnRegInUse.remove(reg);
        }
        public void _ReturnRegisters( RiscVBackend.Register ...regs)
        {
            for (RiscVBackend.Register r : regs)
            {
                _returnRegister(r);
            }
        }
        /**
         * An analyzer for the function described by FUNCINFO0, which is null
         * for the top level.
         */
        StmtAnalyzer(FuncInfo funcInfo0)
        {
            funcInfo = funcInfo0;
            if (funcInfo == null) {
                sym = globalSymbols;
            } else {
                sym = funcInfo.getSymbolTable();
            }
            epilogue = generateLocalLabel();

            MAX_TEMPS = _getFnTempsCount(funcInfo0);
            curTemp = AsmHelper.initTemps(backend, MAX_TEMPS);
            _enterNewRegisterSpace(funcInfo);
        }

        @Override
        public Void analyze(ReturnStmt stmt) {
            // TODO: this assumes that an @f.size constant had been defined. It hasn't been (yet).
            // computes return value
            if (stmt.value != null)
                stmt.value.dispatch(this);
            else
                bke.emitLI(A0, 0, "Return None implicitly");
            // _emitSeparator("<<<epilogue", ".");
            backend.emitLW(RA, FP, -4, "Get return address");
            backend.emitLW(FP, FP, -8, "Use control link to restore caller's fp");
            backend.emitADDI(SP, SP, _getFnArSize(funcInfo), "Restore stack pointer");
            backend.emitJR(RA, "Return to caller");
            // _emitSeparator("epilogue>>>", ".");
            return null;
        }

        @Override
        public Void analyze(BinaryExpr be)
        {
            Label evaluateSecondExpressionLocalLabel = generateLocalLabel();
            Label exitBinaryExprLocalLabel = generateLocalLabel();

            be.left.dispatch(this);
            // _pushRegToStack(A0, "Store binop's left operand to stack");
            int left = pushTemp(A0, "left-operand", "Store binop's left operand to stack");

            //OR short-circuiting
            if (be.operator.equals("or"))
            {
                backend.emitLI(T0, 1, "Load 1 into temp reg");
                backend.emitBEQ(A0, T0, exitBinaryExprLocalLabel, "Compare if A0 is true");
                backend.emitJ(evaluateSecondExpressionLocalLabel, "Jump to exit binary expr local label");
            }

            //AND short-circuiting
            if (be.operator.equals("and"))
            {
                backend.emitLI(T0, 0, "Load 0 into temp reg");
                backend.emitBEQ(A0, T0, exitBinaryExprLocalLabel, "Compare if A0 is false");
                backend.emitJ(evaluateSecondExpressionLocalLabel, "Jump to exit binary expr local label");
            }

            backend.emitLocalLabel(evaluateSecondExpressionLocalLabel, "Evaluate OR second expression");
            be.right.dispatch(this);
            // _popStackToReg(T1, "Binop's left operand from stack to `T1`.");
            loadTempToReg(T1, left, "load binop's left operand from stack to `T1`");

            switch (be.operator)
            {
                case "+":
                    if (be.left.getInferredType().isListType())
                    {
                        pushTemp(T1, "left-expr", "push left list to stack");
                        pushTemp(A0, "right-expr", "push right list to stack");
                        int token = shrinkTopStackTo(curTemp, "shrink stack");
                        bke.emitJAL(concatListLabel, "+ two lists");
                        inflateStack(token, "restore stack");
                        popNTemps(2, "pop left-expr and right-expr off stack");
                    } else if (be.left.getInferredType().equals(Type.STR_TYPE) && be.right.getInferredType().equals(Type.STR_TYPE)) {
                        //If operating on strings then we should return new concatenated string
                        pushTemp(T1, "left-expr", "push left string to stack");
                        pushTemp(A0, "right-expr", "push right string to stack");
                        int token = shrinkTopStackTo(curTemp, "shrink stack");
                        concatStrs();
                        //Set SP back to stack frame top
                        inflateStack(token, "restore stack");
                        popNTemps(2, "pop left-expr and right-expr off stack");

//                        backend.emitADDI(SP, SP, -(_getFnArSize(funcInfo)), "Set SP back to stack frame top");
                    } else {
                        backend.emitADD(A0, T1, A0, "+ two operands");
                    }
                    break;
                case "-":
                    backend.emitSUB(A0, T1, A0, "- two operands");
                    break;
                case "*":
                    backend.emitMUL(A0, T1, A0, "* two operands");
                    break;
                case "//":
                    Label nonzeroDiv = generateLocalLabel();
                    Label differentSign = generateLocalLabel();
                    Label divFinished = generateLocalLabel();
                    bke.emitBNEZ(A0, nonzeroDiv, "Ensure non-zero divisor");
                    bke.emitJ(errorDiv, "jump to div=0 error handler");
                        bke.emitLocalLabel(nonzeroDiv, "when division is non-zero");
                        bke.emitXOR(T2, T1, A0, "check for same sign");
                        bke.emitBLTZ(T2, differentSign, "if !=, needs to adjust left operand before division");

                        backend.emitDIV(A0, T1, A0, "// two operands");
                        bke.emitJ(divFinished, "if == sign, just // then finish");

                        //
                        bke.emitLocalLabel(differentSign, "operands different signs.");
                        bke.emitSLT(T2, ZERO, A0, "t2 = 1 if right > 0 else 0");
                        bke.emitADD(T2, T2, T2, "t2 = 2 * t2");
                        bke.emitADDI(T2, T2, -1, "temp = 1 if right >= 0 else -1");
                        bke.emitADD(T2, T1, T2, "adjust left operand");
                        bke.emitDIV(T2, T2, A0, "adjusted division");
                        bke.emitADDI(A0, T2, -1, "complete division");

                    bke.emitLocalLabel(divFinished, "div finished");
                    break;
                case "%":
                    Label nonzeroMod = generateLocalLabel();
                    Label noRem = generateLocalLabel();
                    bke.emitBNEZ(A0, nonzeroMod, "Ensure non-zero divisor");
                    bke.emitJ(errorDiv, "jump to div=0 error handler");
                    bke.emitLocalLabel(nonzeroMod, "when division is non-zero");
                    bke.emitREM(T2, T1, A0, "operator rem");
                    bke.emitBEQZ(T2, noRem, "if remainder, no adjustment");
                    bke.emitXOR(T3, T2, A0, "check for != signs");
                    bke.emitBGEZ(T3, noRem, "don't adjust if signs ==");
                    // bke.emitADD(A0, T2, A0, "adjust");
                    bke.emitADD(T2, T2, A0, "adjust");

                    bke.emitLocalLabel(noRem, "store result");
                    bke.emitMV(A0, T2, "store result");
                    // backend.emitREM(A0, T1, A0, "% two operands");
                    break;
                case "==":
                    //Erroring
                    //backend.emitSNEZ(T1, T1, null);
                    //backend.emitSEQZ(A0, A0, null);
                    //backend.emitXOR(A0, T1, A0, "== operator");

                    if (be.left.getInferredType().equals(Type.STR_TYPE))
                    {
                        pushTemp(T1, "left-expr", "push left string to stack");
                        pushTemp(A0, "right-expr", "push right string to stack");
                        int token = shrinkTopStackTo(curTemp, "shrink stack");
                        bke.emitJAL(strEql, "call string == function");
                        //Set SP back to stack frame top
                        inflateStack(token, "restore stack");
                        popNTemps(2, "pop left-expr and right-expr off stack");
                    }
                    else
                    {
                        Label equalLocalLabel = generateLocalLabel();
                        Label exitLocalLabel = generateLocalLabel();
                        backend.emitBEQ(A0, T1, equalLocalLabel, "==: Compare if A0 & T1 are equal");
                        backend.emitLI(A0, 0, "Set A0 to be False (0)");
                        backend.emitJ(exitLocalLabel, "Jump to exit local label");
                        backend.emitLocalLabel(equalLocalLabel, "Equal Local Label");
                        backend.emitLI(A0, 1, "Set A0 to be True (1)");
                        backend.emitLocalLabel(exitLocalLabel, "Exit Local Label");
                        break;
                    }
                case "!=":
                    //Erroring
                    //backend.emitSNEZ(T1, T1, null);
                    //backend.emitSNEZ(A0, A0, null);
                    //backend.emitXOR(A0, T1, A0, "!= operator");

                    Label equalLocalLabel2 = generateLocalLabel();
                    Label exitLocalLabel2 = generateLocalLabel();
                    backend.emitBEQ(A0, T1, equalLocalLabel2, "!=: Compare if A0 & T1 are equal");
                    backend.emitLI(A0, 1, "Set A0 to be True (1)");
                    backend.emitJ(exitLocalLabel2, "Jump to exit local label");
                    backend.emitLocalLabel(equalLocalLabel2, "Equal local label");
                    backend.emitLI(A0, 0, "Set A0 to be False (0)");
                    backend.emitLocalLabel(exitLocalLabel2, "Exit local label");
                    break;
                case ">":
                    backend.emitSUB(A0, A0, T1, ">: Subtract T1 (Left) from A0 (Right)");
                    backend.emitLI(T2, 0, "Load 0 into temp reg");
                    backend.emitSLT(A0, A0, T2, "Check if A0 < 0, if so set A0 to 0 else 1");
                    break;
                case ">=":
                    Label greaterOrEqualLocalLabel = generateLocalLabel();
                    Label exitLocalLabel3 = generateLocalLabel();
                    backend.emitBGE(T1, A0, greaterOrEqualLocalLabel, ">=: Compare if T1 >= A0");
                    backend.emitLI(A0, 0, "T1 is NOT greater than A0, Set A0 to False (0)");
                    backend.emitJ(exitLocalLabel3, "Jump to exit local label");
                    backend.emitLocalLabel(greaterOrEqualLocalLabel, null);
                    backend.emitLI(A0, 1, "T1 is greater than A0, Set A0 to True (1)");
                    backend.emitLocalLabel(exitLocalLabel3, "Exit local label");
                    break;
                case "<":
                    backend.emitSUB(A0, T1, A0, "<: Subtract A0 (Right) from T1 (Left)");
                    backend.emitLI(T2, 0, "Load 0 into temp reg");
                    backend.emitSLT(A0, A0, T2, "Check if A0 < 0, if so set A0 to 1 else 0");
                    break;
                case "<=":
                    Label lessOrEqualLocalLabel = generateLocalLabel();
                    Label exitLocalLabel4 = generateLocalLabel();
                    backend.emitBGE(A0, T1, lessOrEqualLocalLabel, "<=: Compare if T1 <= A0");
                    backend.emitLI(A0, 0, "A0 is NOT greater than T1, Set A0 to False (0)");
                    backend.emitJ(exitLocalLabel4, "Jump to exit local label");
                    backend.emitLocalLabel(lessOrEqualLocalLabel, "Less than or equal to local label");
                    backend.emitLI(A0, 1, "A0 is greater than T1, Set A0 to True (1)");
                    backend.emitLocalLabel(exitLocalLabel4, "Exit local label");
                    break;
                case "or":
                    backend.emitOR(A0, A0, T1, "or: OR A0 and T1");
                    break;
                case "and":
                    backend.emitOR(A0, A0, T1, "and: OR A0 and T1");
                    backend.emitLI(T0, 0, "Load 0 into temp reg");
                    backend.emitSUB(A0, T0, A0, "Negate OR operation to get ADD");
                    break;
                case "is":
                    backend.emitXOR(A0, A0, T1, "compare references");
                    backend.emitSEQZ(A0, A0, "Operator is");
                    break;
            }
            popNTemps(1, "pop [left-operand]");
            backend.emitLocalLabel(exitBinaryExprLocalLabel, "Exit binary expression local label");
            return null;
        }

        @Override
        public Void analyze(IntegerLiteral intLit) {
            backend.emitLI(A0, intLit.value, format("Load integer literal: %d", intLit.value));
            // wrapInteger();
            return null;
        }

        @Override
        public Void analyze(StringLiteral strLit) {
            Label lbl = constants.getStrConstant(strLit.value);
            backend.emitLA(A0, lbl, format("Load string literal: \"%s\"", escape(strLit.value)));
            return null;
        }

        @Override
        public Void analyze(NoneLiteral noneLit) {
            backend.emitMV(A0, ZERO, "Load None");
            return null;
        }

        // TODO:: SHOULD NOT USE! Instead, use pushTemp/loadTempToReg/popTempToReg
        protected Integer _pushRegToStack(RiscVBackend.Register reg, String cmt) {
            backend.emitADDI(SP, SP, -4, cmt);
            backend.emitSW(reg, SP, 0, format("push reg %s to stack", reg.toString()));
            return null;
        }

        // TODO:: SHOULD NOT USE! Instead, use pushTemp/loadTempToReg/popTempToReg
        protected Integer _popStackToReg(RiscVBackend.Register reg, String cmt) {
            backend.emitLW(reg, SP, 0, format("pop stack to reg %s", reg.toString()));
            backend.emitADDI(SP, SP, +4, cmt);
            return null;
        }

        @Override
        public Void analyze(BooleanLiteral bl) {
            //Store boolean in A0 reg?
            //Booleans - True: 1 and False: 0
            backend.emitLI(A0, bl.value ? 1 : 0, format("Load boolean immediate \"%b\" into A0", bl.value));
            return null;
        }

        @Override
        public Void analyze(ExprStmt es) {
            es.expr.dispatch(this);
            return null;
        }

        public Void loadLocalVarToReg(VarInfo svi, RiscVBackend.Register reg) {
            //Don't think this is correct ???
            int varIdx = funcInfo.getVarIndex(svi.getVarName()) - funcInfo.getParams().size();
            backend.emitLW(reg, FP, -varIdx * backend.getWordSize() - 4,
                    format("[fn=%s] load local VAR `%s: %s` TO reg `%s`",
                            funcInfo.getFuncName(), svi.getVarName(), svi.getVarType(), reg.toString()));
            return null;
        }

        public Void pushRegToLocalVar(RiscVBackend.Register reg, VarInfo svi) {
            int varIdx = funcInfo.getVarIndex(svi.getVarName()) - funcInfo.getParams().size();
            backend.emitSW(reg, FP,
                    -varIdx * backend.getWordSize() - 4,
                    // -4 here because the return addr + control link is already accounted
                    // for in the result of getVarIndex and the fact that fp is a past-the-beginning pointer
                    format("[fn=%s] store local VAR `%s: %s` FROM reg `%s`",
                            funcInfo.getFuncName(), svi.getVarName(), svi.getVarType(), reg.toString()));
            return null;
        }

        public Void loadLocalVarToReg(
                FuncInfo fn, int varIdx,
                RiscVBackend.Register fp, RiscVBackend.Register dest,
                String cmt)
        {
            return AsmHelper.loadLocalVarToReg(backend, fn, varIdx, fp, dest, cmt);
        }

        public Void loadLocalParamToReg(VarInfo svi, RiscVBackend.Register reg) {
            int varIdx = funcInfo.getVarIndex(svi.getVarName());
            backend.emitLW(reg, FP, +(funcInfo.getParams().size() - 1 - varIdx) * backend.getWordSize(),
                    format("[fn=%s] load local PARAM `%s: %s` to reg `%s`",
                            funcInfo.getFuncName(), svi.getVarName(), svi.getVarType(), reg.toString()));
            return null;
        }

        // this fn should be used to simplify `analyze(Identifier id)`
        // this will walk the static links and find the offset of ident relative to `fp`.
        public void walkAndFindOffsetOfId(
                FuncInfo fni,
                String id,
                RiscVBackend.Register fp,
                RiscVBackend.Register dest,
                String cmnt,
                Func5<RiscVBackend, RiscVBackend.Register, RiscVBackend.Register, Integer, String, Void> op)
        {
            FuncInfo actualOuterScope = fni;
            while (actualOuterScope != null)
            {
                if (actualOuterScope.getLocals().stream().anyMatch(lc -> lc.getVarName().equals(id)) ||
                        actualOuterScope.getParams().contains(id))
                {
                    int varIdx = actualOuterScope.getVarIndex(id);
                    AsmHelper._accessRegToVar(
                            backend, actualOuterScope,
                            varIdx, fp, dest,
                            cmnt, op);
                    break;
                }
                else
                {
                    String parentFuncInfoName = actualOuterScope.getParentFuncInfo() == null ? "NULL" : actualOuterScope.getParentFuncInfo().getFuncName();
                    if (actualOuterScope.getParentFuncInfo() != null)
                    {
                        AsmHelper.loadLocalVarToReg(backend,
                                actualOuterScope, -1, fp, fp,
                                format("Load static link from %s to %s",
                                        actualOuterScope.getFuncName(),
                                        parentFuncInfoName));
                    }
                    actualOuterScope = actualOuterScope.getParentFuncInfo();
                }
            }
        }

        @Override
        public Void analyze(Identifier id)
        {
            if (funcInfo != null) {
                if (funcInfo.getLocals().stream().anyMatch(lc -> lc.getVarName().equals(id.name))
                        || funcInfo.getParams().contains(id.name)) {
                    if (id.name.equals("self")) {
                        ClassInfo classInfo = (ClassInfo) sym.get(id.getInferredType().className());
                        String objectClassName = classInfo.getClassName();
                        backend.emitLA(A0, classInfo.getPrototypeLabel(), format("get pointer to prototype: %s", objectClassName));
                    } else {
                        int index = funcInfo.getVarIndex(id.name);
                        StackVarInfo vi = (StackVarInfo) funcInfo.getSymbolTable().get(id.name);

                        if (index < funcInfo.getParams().size()) {
                            _AssertRegistersFree(A0);
                            return loadLocalParamToReg(vi, A0);
                        } else {
                            _AssertRegistersFree(A0);
                            return loadLocalVarToReg(vi, A0);
                        }
                    }
                } else // id must be nonlocal or declared somewhere in a previous scope
                {
                    //Walk up the static links to find the correct scope that hosts the desired identifier
                    FuncInfo actualOuterScope = funcInfo;
                    _AssertRegistersFree(A0, T0);
                    backend.emitMV(T0, FP, format("Configuration for getting static link of %s", actualOuterScope.getFuncName()));
                    while (actualOuterScope != null) {
                        if (actualOuterScope.getLocals().stream().anyMatch(lc -> lc.getVarName().equals(id.name)) ||
                                actualOuterScope.getParams().contains(id.name)) {
                            // t0 should now have the fp of the static-scope's AR
                            StackVarInfo svi = (StackVarInfo) actualOuterScope.getSymbolTable().get(id.name);
                            int varIdx = actualOuterScope.getVarIndex(id.name);

                            if (id.name.equals("self")) {
                                ClassInfo classInfo = (ClassInfo) sym.get(id.getInferredType().className());
                                String objectClassName = classInfo.getClassName();
                                backend.emitLA(A0, classInfo.getPrototypeLabel(), format("get pointer to prototype: %s", objectClassName));
                            } else {
                                if (varIdx < actualOuterScope.getParams().size()) {
                                    return AsmHelper.loadLocalVarToReg(
                                            backend,
                                            actualOuterScope,
                                            varIdx,
                                            T0,
                                            A0,
                                            "Load param " + svi.getVarName() + " into A0");
                                } else {
                                    int offset = (-(varIdx - actualOuterScope.getParams().size()) * backend.getWordSize()) - 4;
                                    backend.emitLW(A0, T0, offset,
                                            format("[fn=%s] load NON-LOCAL param `%s: %s` to reg %s",
                                                    actualOuterScope.getFuncName(),
                                                    svi.getVarName(),
                                                    svi.getVarType(),
                                                    "A0"));
                                }
                            }
                            break;
                        } else {
                            String parentFuncInfoName = actualOuterScope.getParentFuncInfo() == null ? "NULL" : actualOuterScope.getParentFuncInfo().getFuncName();

                            if (actualOuterScope.getParentFuncInfo() != null) {
                                AsmHelper.loadLocalVarToReg(backend,
                                        actualOuterScope, -1, T0, T0,
                                        format("Load static link from %s to %s",
                                                actualOuterScope.getFuncName(),
                                                parentFuncInfoName));
                            }

                            actualOuterScope = actualOuterScope.getParentFuncInfo();
                        }
                    }
                }
            }

            String idName = id.name;
            SymbolInfo idSymbolInfo = sym.get(idName);

            if (idSymbolInfo instanceof GlobalVarInfo) {
                backend.emitLW(A0, ((GlobalVarInfo) idSymbolInfo).getLabel(), "Load identifier label into A0");
            }

            return null;
        }

        @Override
        public Void analyze(UnaryExpr ue)
        {
            String operator = ue.operator;
            ue.operand.dispatch(this);

            if (operator.equals("-")) {
                backend.emitLI(T0, -1, "Store -1");
                backend.emitMUL(A0, A0, T0, "Multiply A0 by -1");
            }
            return null;
        }

        @Override
        public Void analyze(MemberExpr me) {
            Label notNoneLocalLabel = generateLocalLabel();

            String objectName = me.object.getInferredType().className();
            String memberName = me.member.name;
            me.object.dispatch(this);

            //Check to see if object (A0) is None or not
            backend.emitBNEZ(A0, notNoneLocalLabel, "Ensure not None");
            //Object is None
            backend.emitJ(errorNone, format("[GOTO]: %s", errorNone.labelName));

            //Object is not None
            backend.emitLocalLabel(notNoneLocalLabel, format("[GOTO]: %s", notNoneLocalLabel.labelName));

            //Check to see if it is an attribute or a method
            if (me.getInferredType().isFuncType()) {
                //Go to object's dispatch table and retrieve method's location
                ClassInfo meObjectClassInfo = (ClassInfo) sym.get(objectName);
                int methodOffset = meObjectClassInfo.getMethodIndex(memberName) * (backend.getWordSize());
                backend.emitLA(A0, meObjectClassInfo.getDispatchTableLabel(), format("load %s's dispatch table label into A0", objectName));
                backend.emitLW(A0, A0, methodOffset, format("load address of method: %s.%s", objectName, memberName));
            } else {
                int attributeOffsetInWords = getObjectAttributeOffsetInWords(objectName, memberName);
                backend.emitLW(A0, A0, attributeOffsetInWords, format("get attribute %s.%s", objectName, memberName));
            }

            return null;
        }

        @Override
        public Void analyze(CallExpr ce)
        {
            String functionName = ce.function.name;
            SymbolInfo ceSymbolInfo = sym.get(functionName);
            // TODO:: add logic for method invocation here.

            //Special cases: int and bool unboxed
            if ((functionName.equals("int") || functionName.equals("bool"))
                    && ce.args.size() == 0) {
                backend.emitMV(A0, ZERO, "special cases: int and bool unboxed");
                return null;
            }

            if (ceSymbolInfo instanceof FuncInfo) {
                //FUNCTIONS
                FuncInfo functionInfo = (FuncInfo) sym.get(functionName);
                List<String> functionParams = functionInfo.getParams();

                List<Integer> tempLocs = new ArrayList<>();
                // If the callee is statically nested, first push the `static link`
                if (functionInfo.getParentFuncInfo() != null)
                {
                    // Retrieve a static link to the static outer scope.
                    FuncInfo staticOuterScope = functionInfo.getParentFuncInfo();
                    FuncInfo actualOuterScope = funcInfo;
                    backend.emitMV(T0, FP, format("Configure getting static link to %s", staticOuterScope.getFuncName()));

                    while (!actualOuterScope.equals(staticOuterScope))
                    {
                        // deference static link
                        // backend.emitLW(T0, T0, 0, format("Get static link to %s", actualOuterScope.getFuncName()));
                        AsmHelper.loadLocalVarToReg(backend, actualOuterScope, -1, T0, T0,
                                format("Get static link from %s to %s",
                                        actualOuterScope.getFuncName(),
                                        actualOuterScope.getParentFuncInfo().getFuncName()));
                        actualOuterScope = actualOuterScope.getParentFuncInfo();
                    }
                    // now push static link as sort of "-1"-st argument.
                    // _pushRegToStack(T0, format("Push static link to \"%s\" to stack", actualOuterScope.getFuncName()));
                    tempLocs.add(pushTemp(T0, "static-link",
                            format("Push static link to \"%s\" to stack", actualOuterScope.getFuncName())));
                    // stackGrowth++;
                }

                for (int i = 0; i < ce.args.size(); i++)
                {
                    Expr argExpr = ce.args.get(i);
                    String paramName = functionParams.get(i);
                    StackVarInfo paramInfo = (StackVarInfo) functionInfo.getSymbolTable().get(paramName);

                    //Should output result into A0 reg
                    argExpr.dispatch(this);

                    //Handle "wrapping" integers and booleans
                    if (paramInfo.getVarType().equals(Type.OBJECT_TYPE)
                            && argExpr.getInferredType().equals(Type.INT_TYPE))
                    {
                        // Call Int Wrapping Code Emitter
                        wrapInteger();
                    }

                    if (paramInfo.getVarType().equals(Type.OBJECT_TYPE)
                            && argExpr.getInferredType().equals(Type.BOOL_TYPE))
                    {
                        // Call Bool Wrapping Code Emitter: Create Bool object
                        wrapBoolean();
                    }

                    // _pushRegToStack(A0, format("push arg %d-th `%s` of \"%s\" to stack", i, paramName, ce.function.name));
                    tempLocs.add(pushTemp(A0,
                            format("arg %d-th", i),
                            format("push arg %d-th `%s` of \"%s\" to stack", i, paramName, ce.function.name)));
                    // stackGrowth++;
                }

                int tk = shrinkTopStackTo(curTemp, "shrink stack");
                backend.emitJAL(functionInfo.getCodeLabel(), "Call function: " + functionName);
                inflateStack(tk, "inflate stack");
                popNTemps(tempLocs.size(), "popped arguments off temp-stack");
            } else if (ceSymbolInfo instanceof ClassInfo) {
                //Instantiate new object (new)
                ClassInfo ceClassInfo = (ClassInfo) ceSymbolInfo;
                String objectClassName = ceClassInfo.getClassName();
                backend.emitLA(A0, ceClassInfo.getPrototypeLabel(), format("get pointer to prototype: %s", objectClassName));
                backend.emitInsn("jal alloc", "allocate new object in A0");
                pushTemp(A0, format("%s prototype", objectClassName), format("push %s prototype to stack", objectClassName));
                int token = shrinkTopStackTo(curTemp, "shrink stack");
                backend.emitLW(A1, A0, 8, "load addr of new obj's dispatch table");
                backend.emitLW(A1, A1, 0, format("load addr of %s.__init__", objectClassName));
                backend.emitJALR(A1, format("invoke %s.__init__", objectClassName));
                //Set SP back to stack frame top
                inflateStack(token, "restore stack");
                popTempToReg(A0, "pop new object addr to A0");
            }
            return null;
        }

        @Override
        public Void analyze(IfExpr ie)
        {
            Label elseBranch = generateLocalLabel();
            Label endOfExpr = generateLocalLabel();

            ie.condition.dispatch(this);
            backend.emitBEQZ(A0, elseBranch, "If A0 == 0, jump to falseElseBranch");
            ie.thenExpr.dispatch(this);
            bke.emitJ(endOfExpr, "jump over if-expr");

            // else:
            bke.emitLocalLabel(elseBranch, "else-branch");
            ie.elseExpr.dispatch(this);

            bke.emitLocalLabel(endOfExpr, "continue-after-if-expr");
            return null;
        }

        @Override
        public Void analyze(MethodCallExpr mce) {
            List<Integer> tempLocs = new ArrayList<>();

            for (int i = 0; i < mce.args.size(); i++)
            {
                Expr argExpr = mce.args.get(i);
                argExpr.dispatch(this);

                tempLocs.add(pushTemp(A0,
                        format("arg %d-th", i),
                        format("push arg %d-th to stack", i)));
            }

            mce.method.dispatch(this);

            int token = shrinkTopStackTo(curTemp, "shrink stack");
            backend.emitJALR(A0, "invoke method call expr");
            inflateStack(token, "restore stack");
            popNTemps(tempLocs.size(), "popped arguments off temp-stack");

            return null;
        }

        @Override
        public Void analyze(IfStmt ifStmt) {
            Label falseElseBranch = generateLocalLabel();
            Label finishIfStmtBranch = generateLocalLabel();

            ifStmt.condition.dispatch(this);
            backend.emitBEQZ(A0, falseElseBranch, "If A0 == 0, jump to falseElseBranch");

            //TRUE Branch
            for (Stmt thenStmt : ifStmt.thenBody)
            {
                thenStmt.dispatch(this);
            }
            backend.emitJAL(finishIfStmtBranch, null);

            //FALSE Branch
            backend.emitLocalLabel(falseElseBranch, null);
            for (Stmt elseStmt : ifStmt.elseBody) {
                elseStmt.dispatch(this);
            }

            backend.emitLocalLabel(finishIfStmtBranch, null);
            return null;
        }

        @Override
        public Void analyze(AssignStmt as)
        {
            as.value.dispatch(this);
            int rhs = pushTemp(A0, "assignt-stmt's value", "push RHS to temp-stack");

            for (Expr targetExpr : as.targets)
            {
                // String targetExprName = ((Identifier) targetExpr).name;
                // SymbolInfo targetExprSymbolInfo = sym.get(targetExprName);
                String targetExprName = null;
                SymbolInfo targetExprSymbolInfo = null;
                if (targetExpr instanceof Identifier)
                {
                    targetExprName = ((Identifier) targetExpr).name;
                    targetExprSymbolInfo = sym.get(targetExprName);
                }
                else if (targetExpr instanceof IndexExpr)
                {
                    _emitSeparator("assign-to-index-expr", "%");

                    addressIndexExpr((IndexExpr) targetExpr, ie -> {
                        // A1 = list_ptr; A0 = ptr-to-index-elem; T0 = attr __len__;
                        if ( targetExpr.getInferredType().equals(Type.INT_TYPE)
                                || (targetExpr.getInferredType().equals(Type.BOOL_TYPE)) )
                        // no boxing
                        {
                            loadTempToReg(T1, rhs, "load rhs into A0");
                            bke.emitSW(T1, A0, 0, "store rhs to list");
                        }
                    });
                    continue;
                } else if (targetExpr instanceof MemberExpr) {
                    Label notNoneLocalLabel = generateLocalLabel();
                    MemberExpr memberExpr = (MemberExpr) targetExpr;
                    String objectName = memberExpr.object.getInferredType().className();
                    String attributeName = memberExpr.member.name;

                    pushTemp(A0, "rhs value", "push rhs value to stack");
                    int token = shrinkTopStackTo(curTemp, "shrink stack");

                    //Not sure why I can directly store rhs value to the attribute location from the get go??
                    memberExpr.object.dispatch(this);

                    //Check to see if object is none or not
                    backend.emitBNEZ(A0, notNoneLocalLabel, "Ensure not None");
                    //Object is None
                    backend.emitJ(errorNone, format("[GOTO]: %s", errorNone.labelName));

                    //Object is not None
                    backend.emitLocalLabel(notNoneLocalLabel, format("[GOTO]: %s", notNoneLocalLabel.labelName));
                    //Set SP back to stack frame top
                    inflateStack(token, "restore stack");
                    int attributeOffsetInWords = getObjectAttributeOffsetInWords(objectName, attributeName);
                    popTempToReg(T0, "pop rhs value from stack");
                    backend.emitSW(T0, A0, attributeOffsetInWords, format("store dispatched value to %s.%s", objectName, attributeName));

                    continue;
                }

                box(targetExpr, as.value);

                if (targetExprSymbolInfo instanceof GlobalVarInfo)
                {
                    GlobalVarInfo globalTypedVarSymbolInfo = (GlobalVarInfo) targetExprSymbolInfo;
                    backend.emitSW(A0, globalTypedVarSymbolInfo.getLabel(), T1, "Store A0 into global var " + globalTypedVarSymbolInfo.getVarName());
                }
                else if (targetExprSymbolInfo instanceof StackVarInfo)
                {
                    /*
                    *
                    *
                        public void walkAndFindOffsetOfId(
                                FuncInfo fni,
                                Identifier id,
                                RiscVBackend.Register fp,
                                RiscVBackend.Register dest,
                                String cmnt,
                                Func5<RiscVBackend, RiscVBackend.Register, RiscVBackend.Register, Integer, String, Void> op)
                                // op(backend, destination, fp, offset from fp, cmnt);
                        {
                    *
                    * */

                    _AssertRegistersFree(T0);
                    StackVarInfo stackVarInfo = (StackVarInfo) targetExprSymbolInfo;
                    backend.emitMV(T0, FP, format("Get static link of %s", funcInfo.getFuncName()));
                    walkAndFindOffsetOfId(
                            funcInfo,
                            stackVarInfo.getVarName(),
                            T0,
                            A0,
                            format("[fn=%s] load NON-LOCAL param", funcInfo.getFuncName()),
                            (bke, dest, fp, offset, cmnt) -> {
                                bke.emitSW(dest, fp, offset, cmnt);
                                return null;
                            });

                    // StackVarInfo stackVarInfo = (StackVarInfo) targetExprSymbolInfo;
                    // FuncInfo actualOuterScope = funcInfo;
                    // backend.emitMV(T0, FP, format("Get static link of %s", actualOuterScope.getFuncName()));

                    // while (actualOuterScope != null)
                    // {
                    //     if (actualOuterScope.getLocals().stream().anyMatch(lc -> lc.getVarName().equals(stackVarInfo.getVarName())))
                    //     {
                    //         // t0 should now have the fp of the static-scope's AR
                    //         StackVarInfo svi = (StackVarInfo) actualOuterScope.getSymbolTable().get(stackVarInfo.getVarName());
                    //         int varIdx = actualOuterScope.getVarIndex(stackVarInfo.getVarName());
                    //         int offset = (-(varIdx - actualOuterScope.getParams().size()) * backend.getWordSize()) - 4;

                    //         backend.emitSW(A0, T0, offset,
                    //                 format("[fn=%s] load NON-LOCAL param `%s: %s` to reg %s",
                    //                         actualOuterScope.getFuncName(),
                    //                         svi.getVarName(),
                    //                         svi.getVarType(),
                    //                         "A0"));
                    //         break;
                    //     }
                    //     else
                    //     {
                    //         String parentFuncInfoName = actualOuterScope.getParentFuncInfo() == null ? "NULL" : actualOuterScope.getParentFuncInfo().getFuncName();
                    //         if (actualOuterScope.getParentFuncInfo() != null) {
                    //             AsmHelper.loadLocalVarToReg(backend, actualOuterScope, -1, T0, T0,
                    //                     format("Load static link from %s to %s",
                    //                             actualOuterScope.getFuncName(),
                    //                             parentFuncInfoName));
                    //         }
                    //         actualOuterScope = actualOuterScope.getParentFuncInfo();
                    //     }
                    // }
                }
            }

            popNTemps(1, "pop assign-stmt's value");
            return null;
        }

        @Override
        public Void analyze(WhileStmt ws)
        {
            Label whileTopLocalLabel = generateLocalLabel();
            Label whileTrueBodyLabel = generateLocalLabel();
            Label exitWhileLocalLabel = generateLocalLabel();

            //Check if condition is true or not
            backend.emitLocalLabel(whileTopLocalLabel, "Top of while loop");
            ws.condition.dispatch(this);
            backend.emitLI(T0, 1, "Store 1 into temp reg");
            backend.emitBEQ(A0, T0, whileTrueBodyLabel, "Check if condition is true");
            backend.emitJ(exitWhileLocalLabel, "Jump to bottom of while loop to exit");
            //While Loop Body
            backend.emitLocalLabel(whileTrueBodyLabel, "While loop body");
            for (Stmt bodyStmt : ws.body)
            {
                bodyStmt.dispatch(this);
            }
            backend.emitJ(whileTopLocalLabel, "Go back to top of while loop");
            backend.emitLocalLabel(exitWhileLocalLabel, "Bottom of while loop");
            return null;
        }

        public Void analyze(ListExpr le)
        {
            // _emitSeparator("[[ construct-list", ".");
            for (int i = 0; i < le.elements.size(); i++)
            {
                Expr e = le.elements.get(i);
                e.dispatch(this);
                pushTemp(A0, "list-elem", format("construct list element with index= %s", i));
            }

            bke.emitLI(A0, le.elements.size(), "get list's size");
            pushTemp(A0, "list-size", format("push list size (=%d) to stack", le.elements.size()));
            int token = shrinkTopStackTo(curTemp, format("Shrink top of stack before calling `constructList`"));
            // pushTempTopStackAligned(A0, "size", "store size to stack");
            // for (int i = le.elements.size() - 1; i >= 0; i--)
            // {
            //     // Expr e = le.elements.get(i);
            //     // e.dispatch(this);
            //     pushTempTopStackAligned(A0, format("%d-th elem", i), format("push element %d-th to temp-stack", i));
            // }
            bke.emitJAL(consListLabel, "construct list");
            inflateStack(token, "inflate stack");
            popNTemps(1 + le.elements.size(), "Pop temporaries");
            // _emitSeparator("construct-list ]]", ".");
            return null;
        }

        public Void analyze(IndexExpr e)
        {
            return addressIndexExpr(e, ie ->
            {
                if (e.list.getInferredType().isListType())
                {
                    ValueType ty = ie.list.getInferredType().elementType();
                    if (ty.equals(Type.INT_TYPE) || ty.equals(Type.BOOL_TYPE))
                    // these types are unboxed so load value directly
                    {
                        bke.emitLW(A0, A0, 0, "A0 = *ptr-to-first-elem");
                    } else {
                        assert (false);
                    }
                }
            }) ;
        }

        public Void analyze(ForStmt fs)
        {
            Label fl = generateLocalLabel();
            Label endLoop = generateLocalLabel();
            Label notNone = generateLocalLabel();
            // t1 = idx, t0 = list-ptr
            bke.emitMV(T1, ZERO, "initialize for-loop index");
            int idx = pushTemp(T1, "idx", "push idx to temp-stack");
            fs.iterable.dispatch(this);
            bke.emitBNEZ(A0, notNone, "Ensure not none");
            bke.emitJ(errorNone, "Go to None error handler");
            bke.emitLocalLabel(notNone, "Not None");
            int vec = pushTemp(A0, fs.iterable.getInferredType().toString(), "push iterable to temp-stack") ;

            // for-loop:
            bke.emitLocalLabel(fl, "for-loop header");
            loadTempToReg(T0, vec, "pop iterable to t0");
            loadTempToReg(T1, idx, "peek index in temp-stack");

            bke.emitLW(T2, T0, getAttrOffset(listClass, "__len__"), "get attr __len__");
            bke.emitBGEU(T1, T2, endLoop, "end loop if idx >= len(iter)");
            // if not, continue
            bke.emitADDI(T1, T1, 1, "++idx");
            storeTempFromReg(T1, idx, "store index on temp-stack");

            if (fs.iterable.getInferredType().isListType())
            {
                bke.emitADDI(T1, T1, listHeaderWords - 1,
                        "Compute list element offset in words (n - 1 because 1-based index)");
                bke.emitSLLI(T1, T1, 2, "Compute list element offset in bytes");
                bke.emitADD(T1, T0, T1, "t1 = ptr-to-indexed-element");
                bke.emitLW(T0, T1, 0, "t0 = value-at-index");
            }
            else if (fs.iterable.getInferredType().equals(Type.STR_TYPE))
            {
                bke.emitADDI(T1, T1, -1, null);
                bke.emitADDI(T1, T1, (strHeaderWords) * backend.getWordSize(),
                        "Convert index to offset to char in bytes");
                bke.emitADD(T1, T0, T1, "Get pointer to char");
                bke.emitLBU(T1, T1, 0, "Load character");

                bke.emitLI(T0, 20, "load size of string object (in bytes to T0)");
                bke.emitMUL(T1, T1, T0, "t1 = t1 * 20;; Multiply by size of string object");
                bke.emitLA(T0, charTable, "Index into single-char table");
                bke.emitADD(T0, T0, T1, "t0 = pointer-to-specific-string-in-char-table");
            }
            else
            {
                throw new IllegalArgumentException("should be unreachable");
            }
            // t0 = value-at-idx; t1 = ptr-to-index-elem

            // assign to it var
            SymbolInfo si = sym.get(fs.identifier.name);
            if ( fs.identifier.getInferredType().equals(Type.INT_TYPE)
                    || fs.identifier.getInferredType().equals(Type.BOOL_TYPE) )
            { // unboxed
                if (si instanceof GlobalVarInfo)
                    bke.emitSW(T0, ((GlobalVarInfo) si).getLabel(), T1,
                            format("store t0 into global `%s`", fs.identifier.name));
                else
                {
                    bke.emitMV(T2, FP, "t2 = fp");
                    walkAndFindOffsetOfId(funcInfo, fs.identifier.name, T2, T0, "",
                            (bke, r1, r2, i, cmnt) -> {
                                bke.emitSW(r1, r2, i, cmnt);
                                return null;
                            });
                }
            }
            else if (fs.iterable.getInferredType().equals(Type.STR_TYPE))
            {
                if (si instanceof GlobalVarInfo)
                    bke.emitSW(T0, ((GlobalVarInfo) si).getLabel(), T1, null);
            }
            else
            {
                // fs.identifier.dispatch(this);
                // bke.emitSW(T0, A0, 0,
                //         format("make loop-var `%s` points to element t0", fs.identifier.name));
                bke.emitMV(T2, FP, "t2 = fp");
                walkAndFindOffsetOfId(funcInfo, fs.identifier.name, T2, T0, "",
                        (bke, r1, r2, i, cmnt) -> {
                            bke.emitSW(r1, r2, i, cmnt);
                            return null;
                        });
            }

            // potential function invocations.
            fs.body.forEach(s -> s.dispatch(this));

            bke.emitJ(fl, "for-loop footer"); // goto for-loop:

            // exit-loop:
            bke.emitLocalLabel(endLoop, "end loop");

            popNTemps(2, "pop iterable + idx");
            return null;
        }

        /* PRIVATE HELPER METHODS */
        protected void wrapInteger() {
            backend.emitInsn("jal wrapInteger", null);
        }

        protected void wrapBoolean() {
            backend.emitInsn("jal wrapBoolean", null);
        }

        protected void concatStrs() {
            backend.emitInsn("jal strCat", null);
        }

        protected void box(Expr targetExpr, Expr value) {
            //box if value is of type int or bool and target type is object
            if (targetExpr.getInferredType().equals(Type.OBJECT_TYPE) &&
                    value.getInferredType().equals(Type.INT_TYPE))
            {
                wrapInteger();
            }

            if (targetExpr.getInferredType().equals(Type.OBJECT_TYPE) &&
                    value.getInferredType().equals(Type.BOOL_TYPE)) {
                wrapBoolean();
            }
        }
        protected int getObjectAttributeOffsetInWords(String objectName, String attributeName) {
            ClassInfo meObjectClassInfo = (ClassInfo) sym.get(objectName);
            int attributeStartingOffset = 3 * backend.getWordSize();
            int attributeIndex = meObjectClassInfo.getAttributeIndex(attributeName);
            return attributeStartingOffset + (attributeIndex * backend.getWordSize());
        }

        public List<SimpleEntry<RiscVBackend.Register, Integer>>
            _backupRegisters(String cmnt, RiscVBackend.Register...regs)
        {
            SimpleEntry<Integer, List<SimpleEntry<RiscVBackend.Register, Integer>>> ret =
                    AsmHelper.backupRegistersToTemp(bke, MAX_TEMPS, curTemp, cmnt, regs);
            curTemp = ret.getKey();
            return ret.getValue();
        }

        public void
        _restoreRegisters(String cmnt, List<SimpleEntry<RiscVBackend.Register, Integer>> token)
        {
            curTemp = AsmHelper.restoreRegisters(bke, MAX_TEMPS, curTemp, cmnt, token);
            return ;
        }

        public int pushTemp(RiscVBackend.Register reg, String content, String cmnt)
        {
            tempContent.push(content);
            int oldcurtemp = curTemp;
            curTemp = AsmHelper.pushTemp(backend, reg, MAX_TEMPS, curTemp, //_getFnArSize(funcInfo),
                    format("[push-temp `%s`] ", content) + cmnt);
            return oldcurtemp;
        }

        public void loadTempToReg(RiscVBackend.Register reg, int temp, String cmnt)
        {
            String content = tempContent.get(temp - 1);
            AsmHelper.loadTempToReg(backend, reg, MAX_TEMPS, temp,
                    format("[peek-temp `%s`] ", content) + cmnt);
        }

        public void storeTempFromReg(RiscVBackend.Register reg, int temp, String cmnt)
        {
            String content = tempContent.get(temp - 1);
            AsmHelper.storeTempFromReg(backend, reg, MAX_TEMPS, temp,
                    format("[assign-temp `%s`] ", content) + cmnt);
        }

        public int shrinkTopStackTo(int temp, String cmnt)
        {
            AsmHelper.shrinkTopStackTo(backend, MAX_TEMPS, temp,
                    format("[deflate-stack] ") + cmnt);
            return temp;
        }

        public int inflateStack(int temp, String cmnt)
        {
            AsmHelper.inflateStack(backend, MAX_TEMPS, temp,
                    format("[inflate-stack] ") + cmnt);
            return temp;
        }

        public int popNTemps(int N, String cmnt)
        {
            for (; N >= 1; N--)
            {
                curTemp--;
                tempContent.pop();
            }
            if (curTemp < 1) throw new IllegalArgumentException("pop too many");
            return curTemp;
        }

        public int pushTempTopStackAligned(RiscVBackend.Register reg, String content, String cmnt)
        {
            tempContent.push(content);
            int oldcurtemp = curTemp;
            curTemp = AsmHelper.pushTempTopStackAligned(backend, reg, MAX_TEMPS, oldcurtemp, //_getFnArSize(funcInfo),
                    format("[push-temp-top-aligned `%s`] ", content) + cmnt);
            return oldcurtemp;
        }

        public int popTempToReg(RiscVBackend.Register reg, String cmnt)
        {
            String cnt = tempContent.pop();
            int oldcurtemp = curTemp;
            curTemp = AsmHelper.popTempToReg(backend, reg, MAX_TEMPS, oldcurtemp, //_getFnArSize(funcInfo),
                    format("[pop-temp `%s`] ", cnt) + cmnt);
            return oldcurtemp;
        }

        // within opAddr, the following are true
        // A1 = list_ptr; A0 = ptr-to-indexed-elem; T0 = attr __len__;
        protected Void addressIndexExpr(IndexExpr ie, Consumer<IndexExpr> opAddr)
        {
            Label notNone = generateLocalLabel();
            Label withinBound = generateLocalLabel();

            assert(getAttrOffset(strClass, "__len__") == getAttrOffset(listClass, "__len__"));
            bke.emitLW(T0, A1, getAttrOffset(listClass, "__len__"), "Load attribute __len__");

            // Get list and store on stack
            ie.list.dispatch(this); // A0 = list
            pushTemp(A0,
                    "list",
                    format("push list %s onto temp", ie.list.getInferredType()));

            ie.index.dispatch(this); // A0 = index

            popTempToReg(A1, "retrieve list into A1");

            bke.emitBNEZ(A1, notNone, "Ensure not none");
            bke.emitJ(errorNone, "Goes to none handler");

            // not_none:
            bke.emitLocalLabel(notNone, "Not none");

            //The same? Since the length is the first attribute in the object prototype?
            if (ie.list.getInferredType().equals(Type.STR_TYPE)) {
                bke.emitLW(T0, A1, getAttrOffset(strClass, "__len__"), "get attribute __len__ for str");
            } else {
                bke.emitLW(T0, A1, getAttrOffset(listClass, "__len__"), "get attribute __len__ for list");
            }

            bke.emitBLTU(A0, T0, withinBound, "Index within bound");
            bke.emitJ(errorOob, "Go to OOB error handler");

            // within_bound:
            bke.emitLocalLabel(withinBound, "Index within bound");

            if (ie.list.getInferredType().equals(Type.STR_TYPE)) {
                //If indexing into to a string
                bke.emitADDI(T0, A0, 16, "Index to offset to char in bytes");
                bke.emitADD(T0, A1, T0, "Get pointer to char");
                bke.emitLBU(T0, T0, 0, "Load char");
                bke.emitLI(T1, 20, null);
                bke.emitMUL(T0, T0, T1, "Multiply by size of string object");
                bke.emitLA(A0, charTable, "Index into char table");
                bke.emitADD(A0, A0, T0, null);
            } else {
                bke.emitADDI(A0, A0, listHeaderWords, "Compute list element offset in words");
                bke.emitLI(T5, 4, "T5 = 4");
                // bke.emitSLLI(A0, A0, 2, "List element offset in bytes");
                bke.emitMUL(A0, T5, A0, "List element offset in bytes");
                bke.emitADD(A0, A0, A1, "A0 = ptr-to-first-elem");
            }

            // A1 = list_ptr; A0 = ptr-to-first-elem; T0 = attr __len__;
            // invoke op
            opAddr.accept(ie);

            // popNTemps(1, "Pop temp");

            return null;
        }
    }

    /**
     * Emits custom code in the CODE segment.
     * <p>
     * This method is called after emitting the top level and the
     * function bodies for each function.
     * <p>
     * You can use this method to emit anything you want outside of the
     * top level or functions, e.g. custom routines that you may want to
     * call from within your code to do common tasks. This is not strictly
     * needed. You might not modify this at all and still complete
     * the assignment.
     * <p>
     * To start you off, here is an implementation of three routines that
     * will be commonly needed from within the code you will generate
     * for statements.
     * <p>
     * The routines are error handlers for operations on None, index out
     * of bounds, and division by zero. They never return to their caller.
     * Just jump to one of these routines to throw an error and
     * exit the program. For example, to throw an OOB error:
     * backend.emitJ(errorOob, "Go to out-of-bounds error and abort");
     */
    protected void emitCustomCode() {
        emitErrorFunc(errorNone, "Operation on None", ERROR_NONE);
        emitErrorFunc(errorDiv, "Division by zero", ERROR_DIV_ZERO);
        emitErrorFunc(errorOob, "Index out of bounds", ERROR_OOB);
        emitWrappedInt();
        emitWrappedBoolean();
        emitConcatList();
        emitConsList();
        emitCharTable();
        emitStrCat();
        emitStrEql();
    }

    private static final int listHeaderWords = 4; // last word is __len__
    private static final int strHeaderWords = 4; // last word is __len__
    private static final int D__elts__ = 16;
    private static final int D__len__ = 12;
    private static final int D__str__ = 16;

    protected void emitStrEql()
    {
        Label streqlNo = generateLocalLabel();
        Label strelEnd = generateLocalLabel();

        bke.emitGlobalLabel(strEql);
        bke.emitADDI(SP, SP, -8, "");
        bke.emitSW(RA, SP, 4, "save ra");
        bke.emitSW(FP, SP, 0, "save fp");
        bke.emitADDI(FP, SP, 8, "");

        bke.emitLW(A1, FP, 4, "");
        bke.emitLW(A2, FP, 0, "");
        bke.emitLW(T0, A1, D__len__, "");
        bke.emitLW(T1, A2, D__len__, "");
        bke.emitBNE(T0, T1, streqlNo, "zero length handler");

        Label loop = generateLocalLabel();
        bke.emitLocalLabel(loop, "");
        bke.emitLBU(T2, A1, D__str__, "");
        bke.emitLBU(T3, A2, D__str__, "");
        bke.emitBNE(T2, T3, streqlNo, "");
        bke.emitADDI(A1, A1, 1, "");
        bke.emitADDI(A2, A2, 1, "");
        bke.emitADDI(T0, T0, -1, "");
        bke.emitBGTZ(T0, loop, "");
        bke.emitLI(A0, 1, "");
        bke.emitJ(strelEnd, "");

        bke.emitLocalLabel(streqlNo, "");
        bke.emitXOR(A0, A0, A0, "empty strings are equal");

        bke.emitLocalLabel(strelEnd, "");
        bke.emitLI(T1, 1, "");
        bke.emitSUB(A0, T1, A0, "flip return value");
        bke.emitLW(RA, FP, -4, "");
        bke.emitLW(FP, FP, -8, "");
        bke.emitADDI(SP, SP, 8, "");
        bke.emitJR(RA, "");
    }

    // optimization: create a table of size=1 strings for easy lookup.
    protected void emitCharTable()
    {
        Label loop = generateLocalLabel();
        bke.emitGlobalLabel(createCharTable);
        bke.emitLA(A0, strClass.getPrototypeLabel(), "get string prototype");
        bke.emitLW(T0, A0, 0, "get str tag");
        bke.emitLW(T1, A0, 4, "get object size");
        bke.emitLW(T2, A0, 8, "Get ptr-to-dispatch-table");
        bke.emitLI(T3, 1, "size of string");

        bke.emitLA(A0, charTable, "get ptr to charTable");
        bke.emitLI(T4, 256, null);
        // bke.emitMV(T5, ZERO, "set up idx = 0");
        bke.emitLI(T5, 0, "set up idx = 0");

        bke.emitLocalLabel(loop, "loop to create char table");
        bke.emitSW(T5, A0, 16, "store the character");
        bke.emitSW(T3, A0, 12, "store size of string");
        bke.emitSW(T2, A0, 8, "store ptr-to-dispatch-table");
        bke.emitSW(T1, A0, 4, "store object size");
        bke.emitSW(T0, A0, 0, "store type tag");

        bke.emitADDI(A0, A0, 20, "jumps to the next location to store character");
        bke.emitADDI(T5, T5, 1, "char = char + 1");
        bke.emitBNE(T4, T5, loop, "goto-loop");

        bke.emitJR(RA, "return");
        bke.emitInsn(".data", null);
        bke.emitInsn(".align 2", "to ensure alignment");

        bke.emitGlobalLabel(charTable);
        bke.emitInsn(".space 5120", null);
        bke.emitInsn(".text", null);
    }

    protected void emitConcatList()
    {
        final int wordSz = backend.getWordSize();
        final int MAX_TEMPS = 16;
        int curTemp = 1;
        int FnArSz = 8 + MAX_TEMPS * wordSz ;

        Label concatNone = generateLocalLabel();
        Label epilogue = generateLocalLabel();
        Label copyArg1 = generateLocalLabel();
        Label copyArg2 = generateLocalLabel();
        Label prepareCopyArg2 = generateLocalLabel();

        bke.emitGlobalLabel(concatListLabel);

        backend.emitADDI(SP, SP, -FnArSz, "Reserve space for stack frame");

        backend.emitSW(RA, SP, FnArSz - 4, "Save return address.");
        backend.emitSW(FP, SP, FnArSz - 8, "Save control link.");
        backend.emitADDI(FP, SP, FnArSz, "`fp` is at old `sp`.");

        // free up registers s1 -> s5
        SimpleEntry<Integer, List<SimpleEntry<RiscVBackend.Register, Integer>>> curTempXToken =
                AsmHelper.backupRegistersToTemp(bke, MAX_TEMPS, curTemp, "backup registers s1->s5",
                        S1, S2, S3, S4, S5);
        curTemp = curTempXToken.getKey(); // these functions are pure so must update manually

        _emitSeparator("Compute sum of list lengths and then allocate", ".");
        // load arg1 and arg2
        bke.emitLW(T0, FP, 4, "t0 = arg1");
        bke.emitLW(T1, FP, 0, "t1 = arg2");
        // asserts neither list is None
        bke.emitBEQZ(T0, concatNone, "asserts t0 not None");
        bke.emitBEQZ(T1, concatNone, "asserts t1 not None");
        // retrieves length
        bke.emitLW(T0, T0, getAttrOffset(listClass, "__len__"), "t0 = t0.__len__");
        bke.emitLW(T1, T1, getAttrOffset(listClass, "__len__"), "t1 = t1.__len__");
        // allocate new array
        bke.emitADD(S5, T0, T1, "s5 = arg1.len + arg2.len");
        bke.emitADDI(A1, S5, listHeaderWords,
                "reserve space for header and load sum into A1 to prep for alloc2");
        bke.emitLA(A0, listClass.getPrototypeLabel(), "A0 = list-prototype (for alloc2)");
        bke.emitJAL(objectAllocResizeLabel, "allocate new list");

        _emitSeparator("initialize newly created array", "_");
        // now initialize the newly allocated list
        bke.emitSW(S5, A0, getAttrOffset(listClass, "__len__"), "initialize new list's size");
        bke.emitMV(S5, A0, "s5 = heap-ptr");
        bke.emitADDI(S3, S5, D__elts__, "s3 = heap-ptr + offset-to-first-element");

        bke.emitLW(S1, FP, 4, "s1 = arg1");
        bke.emitLW(S2, S1, getAttrOffset(listClass, "__len__"), "s2 = arg1.len");

        _emitSeparator("Copy arg1 into allocated list", ".");
        // copying arg1 into newly allocated list
        bke.emitADDI(S1, S1, D__elts__, "s1 = &arg1[0]");
        bke.emitLocalLabel(copyArg1, "copy arg1 to destination");
        bke.emitBEQZ(S2, prepareCopyArg2,
                "loop when s2 > 0; else start initialize the copying of arg2");

        bke.emitLW(A0, S1, 0, "a0 = arg1[0]");
        bke.emitSW(A0, S3, 0, "*ptr-to-first-elem = a0");
        bke.emitADDI(S2, S2, -1, "decrement index s2 = (arg1.len ... 1)");
        bke.emitADDI(S1, S1, 4, "advance to next element of arg1");
        bke.emitADDI(S3, S3, 4, "ptr-to-first-elem += 4");
        bke.emitJ(copyArg1, "continue loop");

        // preparing to copy arg2
        bke.emitLocalLabel(prepareCopyArg2, "preparing to copy arg2");
        bke.emitLW(S1, FP, 0, "s1 = arg2");
        bke.emitLW(S2, S1, getAttrOffset(listClass, "__len__"), "s2 = arg2.len");
        bke.emitADDI(S1, S1, D__elts__, "s1 = &arg2[0]");

        _emitSeparator("Copy arg2 into allocated list", ".");
        // copy arg2
        bke.emitLocalLabel(copyArg2, "copy arg2");
        bke.emitBEQZ(S2, epilogue, "when done copying, go to epilogue");
        bke.emitLW(A0, S1, 0, "a0 = arg2[0]");
        bke.emitSW(A0, S3, 0, "*ptr-to-first-element = arg2[0]");
            // update indices
            bke.emitADDI(S2, S2, -1, "remaining elements -= 1");
            bke.emitADDI(S1, S1, 4, "advance to next element of arg2");
            bke.emitADDI(S3, S3, 4, "ptr-to-first-element += 4");
            bke.emitJ(copyArg2, "loop");

        // epilogue::
        bke.emitLocalLabel(epilogue, "cleanup");
        bke.emitMV(A0, S5, "ret = heap-ptr");
        // restores registers s1 -> s5
        curTemp = AsmHelper.restoreRegisters(bke, MAX_TEMPS, curTemp, "restore registers s1 -> s5",
                curTempXToken.getValue());

        bke.emitLW(RA, FP, -4, "get return addr");
        bke.emitLW(FP, FP, -8, "Use control link to restore caller's fp");
        bke.emitADDI(SP, SP, FnArSz, "restore stack ptr");
        bke.emitJR(RA, "return to caller");

        // concat_none::
        bke.emitLocalLabel(concatNone, "concat_none:");
        bke.emitJ(errorNone, "");
    }

    // a list constructor
    protected void emitConsList()
    {
        bke.emitGlobalLabel(consListLabel);
        Label done = new Label("constructListFinale");
        bke.emitADDI(SP, SP, -8, null);
        bke.emitSW(RA, SP, 4, null);
        bke.emitSW(FP, SP, 0, null);
        bke.emitADDI(FP, SP, 8, "fp is old sp");

        bke.emitLW(A1, FP, 0, "Get list size");
        bke.emitLA(A0, listClass.getPrototypeLabel(), "Get list prototype for alloc2");
        bke.emitBEQZ(A1, done, "If list empty, then we done.");
        // else, lets allocate space for list on the heap
        bke.emitADDI(A1, A1, listHeaderWords, "Allocate sz + 4 to store elements and headers");
        bke.emitJAL(objectAllocResizeLabel, "Allocate space for list on heap");

        // A0 = heap_ptr; T0 = size
        bke.emitLW(T0, FP, 0, "t0 = len");
        bke.emitSW(T0, A0, getAttrOffset(listClass, "__len__"), "store length attr to list on heap");
        // bke.emitSLLI(T1, T0, 2, "t1 = size (in bytes) of list in memory");
        bke.emitLI(T1, 4, "word to bytes conversion");
        bke.emitMUL(T1, T0, T1, "t1 = size (in bytes)  of list in mem");
        bke.emitADD(T1, T1, FP, "t1 now points to start of stack-list");
        bke.emitADDI(T2, A0, D__elts__, "t2 points to first array element");
        // t1 = stack-arr; t2 = heap-arr;

        Label loop = generateLocalLabel();
        bke.emitLocalLabel(loop, "copying contents from stack-list to heap-list");
        bke.emitLW(T3, T1, 0, "t3 = stack-arr[0]");
        bke.emitSW(T3, T2, 0, "heap-arr[0] = t3");
        bke.emitADDI(T1, T1, -4, "stack-arr -= 4");
        bke.emitADDI(T2, T2, 4, "heap-arr += 4");
        bke.emitADDI(T0, T0, -1, "size -= 1");
        bke.emitBNEZ(T0, loop, "if there are still element to be copy, keep copying.");

        // conslist_done:
        bke.emitLocalLabel(done, "just finishing up");
        bke.emitLW(RA, FP, -4, null);
        bke.emitLW(FP, FP, -8, null);
        bke.emitADDI(SP, SP, 8, null);
        bke.emitJR(RA, null);
    }

    /** Emit an error routine labeled ERRLABEL that aborts with message MSG. */
    private void emitErrorFunc(Label errLabel, String msg, int errc)
    {
        backend.emitGlobalLabel(errLabel);
        backend.emitLI(A0, errc, "Exit code for: " + msg);
        backend.emitLA(A1, constants.getStrConstant(msg),
                       "Load error message as str");
        backend.emitADDI(A1, A1, getAttrOffset(strClass, "__str__"),
                         "Load address of attribute __str__");
        backend.emitJ(abortLabel, "Abort");
    }

    private void emitWrappedBoolean() {
        Label emitWrappedBooleanLabel = new Label("wrapBoolean");
        Label localTrueBranchLabel = generateLocalLabel();
        Label boolFalse = new Label("@boolFALSE");

        backend.emitGlobalLabel(emitWrappedBooleanLabel);
        //Erroring
        //        backend.emitSLLI(A0, A0, 4, null);
        //        backend.emitLA(T1, boolFalse, null);
        //        backend.emitADD(A0, A0, T1, null);
        //        backend.emitJR(RA, null);
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

    protected void emitStrCat() {
        Label emitStrCatLabel = new Label("strCat");
        Label emitT0EmptyLabel = generateLocalLabel();
        Label emitT1EmptyLabel = generateLocalLabel();
        Label emitResetLoopAndStoreLabel = generateLocalLabel();
        Label emitLoopAndStoreForFirstStrLabel = generateLocalLabel();
        Label emitLoopAndStoreForSecondStrLabel = generateLocalLabel();
        Label emitAppendNullCharToStrLabel = generateLocalLabel();
        Label emitCallingConventionCleanup = generateLocalLabel();

        backend.emitGlobalLabel(emitStrCatLabel);
        //Calling Convention Configuration
        backend.emitADDI(SP, SP, -12, null);
        backend.emitSW(RA, SP, 8, null);
        backend.emitSW(FP, SP, 4, null);
        backend.emitADDI(FP, SP, 12, null);

        //Load Variables a, b
        backend.emitLW(T0, FP, 4, "Load first string to T0");
        backend.emitLW(T1, FP, 0, "Load second string to T1");

        //Get string lengths for T0 and T1
        backend.emitLW(T0, T0, getAttrOffset(strClass, "__len__"), "Get T0's length");
        backend.emitLW(T1, T1, getAttrOffset(strClass, "__len__"), "Get T1's length");

        //Check if T0 or T1 is empty. If so just return the other string (Concat with empty string)
        backend.emitBEQZ(T0, emitT0EmptyLabel, "TO is empty so just return T1");
        backend.emitBEQZ(T1, emitT1EmptyLabel, "T1 is empty so just return T0");

        //T0 and T1 are not empty so perform concatenation procedure
        //Calculate new String object size (4 + [(k+1) / 4])
        backend.emitADD(T0, T0, T1, "k"); //k
        backend.emitSW(T0, FP, -12, "Store k to stack");
        backend.emitADDI(T0, T0, 4, null);
        backend.emitSRLI(T0, T0, 2, null);
        backend.emitLA(A0, strClass.getPrototypeLabel(), "Get string prototype for alloc2");
        backend.emitADDI(A1, T0, 4, null);
        backend.emitInsn("jal alloc2", "jal alloc");
        //Store string length into __len__ attribute
        backend.emitLW(T0, FP, -12, "Load k from stack");
        backend.emitSW(T0, A0, getAttrOffset(strClass, "__len__"), "Store k to __len__ attr");

        //Store concatenated string to __str__ attribute
        backend.emitADDI(T1, A0, getAttrOffset(strClass, "__str__"), "T1 = address of new __str__ store");
        backend.emitLW(T0, FP, 4, "Load first string to T0");
        backend.emitLW(T2, T0, getAttrOffset(strClass, "__len__"), "T2 = T0's length");
        backend.emitADDI(T0, T0, getAttrOffset(strClass, "__str__"), "T0 = content of 1st string");

        //Loop through all of the characters in T0 and store them sequentially in T1
        backend.emitLocalLabel(emitLoopAndStoreForFirstStrLabel, "[ENTER BRANCH]: Loop and store for first string");
        backend.emitBEQZ(T2, emitResetLoopAndStoreLabel, "Finished storing T0, now do the same for T1");
        backend.emitLBU(T3, T0, 0, "Load byte for first str");
        backend.emitSB(T3, T1, 0, "Store byte into T1");
        backend.emitADDI(T2, T2, -1, "Decrement T0's length by 1");
        backend.emitADDI(T1, T1, 1, "Increment store __str__ address by 1");
        backend.emitADDI(T0, T0, 1, "Increment str address by 1");
        backend.emitJ(emitLoopAndStoreForFirstStrLabel, "[JUMP]: Loop and store for T0");

        backend.emitLocalLabel(emitResetLoopAndStoreLabel, "[ENTER BRANCH]: Reset config for second string looping");
        //Reset "helper" variables
        backend.emitLW(T0, FP, 0, "Load second string to T0");
        backend.emitLW(T2, T0, getAttrOffset(strClass, "__len__"), "T2 = T0's length");
        //backend.emitADDI(T1, T0, getAttrOffset(strClass, "__str__"), "Get second string store __str__ address");
        backend.emitADDI(T0, T0, getAttrOffset(strClass, "__str__"), "T0 = content of 2nd string");

        //Loop and store for T1
        backend.emitLocalLabel(emitLoopAndStoreForSecondStrLabel, "[ENTER BRANCH]: Loop and store for second string");
        backend.emitBEQZ(T2, emitAppendNullCharToStrLabel, "Finish processing T1, jump to add null char to str");
        backend.emitLBU(T3, T0, 0, "Load byte for second str");
        backend.emitSB(T3, T1, 0, "Store byte into T1");
        backend.emitADDI(T2, T2, -1, "Decrement T1's length by 1");
        backend.emitADDI(T1, T1, 1, "Increment store __str__ address by 1");
        backend.emitADDI(T0, T0, 1, "Increment str address by 1");
        backend.emitJ(emitLoopAndStoreForSecondStrLabel, "[JUMP]: Loop and store for T1");

        //T0 is empty. Return T1
        backend.emitLocalLabel(emitT0EmptyLabel, "[ENTER BRANCH]: T0 Empty Return T1");
        backend.emitLW(A0, FP, 0, "Return T1");
        backend.emitJ(emitCallingConventionCleanup, "[JUMP]; Calling Convention Cleanup");

        //T1 is empty. Return T0
        backend.emitLocalLabel(emitT1EmptyLabel, "[ENTER BRANCH]: T1 Empty Return T0");
        backend.emitLW(A0, FP, 4, "Return T0");
        backend.emitJ(emitCallingConventionCleanup, "[JUMP]: Calling Convention Cleanup");

        //Append Null Char to str
        backend.emitLocalLabel(emitAppendNullCharToStrLabel, "[ENTER BRANCH]: Append Null Char to str");
        backend.emitSB(ZERO, T1,0, "Append null char to str");

        //Calling Convention Cleanup
        backend.emitLocalLabel(emitCallingConventionCleanup, "[ENTER BRANCH]: Calling Convention Cleanup");
        backend.emitLW(RA, FP, -4, null);
        backend.emitLW(FP, FP, -8, null);
        backend.emitADDI(SP, SP, 12, null);
        backend.emitJR(RA, "[JUMP]: Exit StrCat");
    }
}
