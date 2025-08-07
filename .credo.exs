%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["mix.exs", "lib/", "test/"],
        excluded: []
      },
      color: true,
      checks: [
        #
        ## Consistency Checks
        #
        {Credo.Check.Consistency.ExceptionNames, []},
        {Credo.Check.Consistency.LineEndings, []},
        {Credo.Check.Consistency.SpaceAroundOperators, []},
        {Credo.Check.Consistency.SpaceInParentheses, []},
        {Credo.Check.Consistency.TabsOrSpaces, []},
        {Credo.Check.Consistency.UnusedVariableNames, []},

        #
        ## Design Checks
        #
        # You can customize the priority of any check
        # Priority values are: `low, normal, high, higher`
        #
        {Credo.Check.Design.DuplicatedCode, [mass_threshold: 65]},
        {Credo.Check.Design.TagFIXME, []},
        # turn this on once the todos are cleaned up
        {Credo.Check.Design.TagTODO, false},

        #
        ## Readability Checks
        #
        # Credo.Check.Readability.AliasAs
        {Credo.Check.Readability.FunctionNames, []},
        # maybe turn this on
        {Credo.Check.Readability.ImplTrue, false},
        {Credo.Check.Readability.MaxLineLength, false},
        {Credo.Check.Readability.ModuleAttributeNames, []},
        {Credo.Check.Readability.ModuleNames, []},
        {Credo.Check.Readability.NestedFunctionCalls, false},
        {Credo.Check.Readability.ParenthesesInCondition, []},
        {Credo.Check.Readability.PredicateFunctionNames, []},
        {Credo.Check.Readability.RedundantBlankLines, false},
        {Credo.Check.Readability.Semicolons, []},
        {Credo.Check.Readability.SeparateAliasRequire, []},
        {Credo.Check.Readability.SpaceAfterCommas, []},
        # maybe turn this on
        {Credo.Check.Readability.Specs, false},
        {Credo.Check.Readability.TrailingBlankLine, false},
        {Credo.Check.Readability.TrailingWhiteSpace, false},
        {Credo.Check.Readability.VariableNames, []},
        {Credo.Check.Readability.WithCustomTaggedTuple, []},

        #
        ## Refactoring Opportunities
        #
        {Credo.Check.Refactor.ABCSize, max_size: 75},
        {Credo.Check.Refactor.AppendSingleItem, []},
        {Credo.Check.Refactor.Apply, []},
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 15},
        {Credo.Check.Refactor.DoubleBooleanNegation, []},
        {Credo.Check.Refactor.FilterFilter, []},
        {Credo.Check.Refactor.FilterReject, []},
        {Credo.Check.Refactor.FunctionArity, []},
        {Credo.Check.Refactor.IoPuts, []},
        {Credo.Check.Refactor.LongQuoteBlocks, []},
        {Credo.Check.Refactor.MapMap, []},
        {Credo.Check.Refactor.MatchInCondition, []},
        {Credo.Check.Refactor.NegatedIsNil, []},
        {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
        {Credo.Check.Refactor.RejectFilter, []},
        {Credo.Check.Refactor.RejectReject, []},

        #
        ## Warnings
        #
        {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
        {Credo.Check.Warning.BoolOperationOnSameValues, []},
        {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
        {Credo.Check.Warning.IExPry, []},
        {Credo.Check.Warning.IoInspect, []},
        {Credo.Check.Warning.LeakyEnvironment, []},
        {Credo.Check.Warning.MapGetUnsafePass, []},
        {Credo.Check.Warning.MixEnv, []},
        {Credo.Check.Warning.OperationOnSameValues, []},
        {Credo.Check.Warning.OperationWithConstantResult, []},
        {Credo.Check.Warning.RaiseInsideRescue, false},
        # maybe turn this on
        {Credo.Check.Warning.SpecWithStruct, false},
        {Credo.Check.Warning.UnsafeExec, []},
        {Credo.Check.Warning.UnsafeToAtom, []},
        {Credo.Check.Warning.UnusedEnumOperation, []},
        {Credo.Check.Warning.UnusedFileOperation, []},
        {Credo.Check.Warning.UnusedKeywordOperation, []},
        {Credo.Check.Warning.UnusedListOperation, []},
        {Credo.Check.Warning.UnusedPathOperation, []},
        {Credo.Check.Warning.UnusedRegexOperation, []},
        {Credo.Check.Warning.UnusedStringOperation, []},
        {Credo.Check.Warning.UnusedTupleOperation, []},
        {Credo.Check.Warning.WrongTestFileExtension, []},

        # Styler Rewrites
        #
        # The following rules are automatically rewritten by Styler and so disabled here to save time
        # Some of the rules have `priority: :high`, meaning Credo runs them unless we explicitly disable them
        # (removing them from this file wouldn't be enough, the `false` is required)
        #
        {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
        {Credo.Check.Consistency.ParameterPatternMatching, false},
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Readability.AliasOrder, false},
        {Credo.Check.Readability.BlockPipe, false},
        {Credo.Check.Readability.LargeNumbers, false},
        {Credo.Check.Readability.ModuleDoc, false},
        {Credo.Check.Readability.MultiAlias, false},
        {Credo.Check.Readability.OneArityFunctionInPipe, false},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
        {Credo.Check.Readability.PipeIntoAnonymousFunctions, false},
        {Credo.Check.Readability.PreferImplicitTry, false},
        {Credo.Check.Readability.SinglePipe, false},
        {Credo.Check.Readability.StrictModuleLayout, false},
        {Credo.Check.Readability.StringSigils, false},
        {Credo.Check.Readability.UnnecessaryAliasExpansion, false},
        {Credo.Check.Readability.WithSingleClause, false},
        {Credo.Check.Refactor.CaseTrivialMatches, false},
        {Credo.Check.Refactor.CondStatements, false},
        {Credo.Check.Refactor.FilterCount, false},
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Refactor.MapJoin, false},
        {Credo.Check.Refactor.NegatedConditionsInUnless, false},
        {Credo.Check.Refactor.NegatedConditionsWithElse, false},
        {Credo.Check.Refactor.PipeChainStart, false},
        {Credo.Check.Refactor.RedundantWithClauseResult, false},
        {Credo.Check.Refactor.UnlessWithElse, false},
        {Credo.Check.Refactor.WithClauses, false}
      ]
    }
  ]
}
