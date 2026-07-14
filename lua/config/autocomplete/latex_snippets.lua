local M = {}

M.filetypes = {
  'tex',
  'latex',
  'plaintex',
  'markdown',
  'rmd',
  'quarto',
}

-- Snippet entry format:
--   { trigger = 'avg', replacement = [=[\avg{ $0 } $1]=], options = 'mA', priority = 1 }
--
-- Keys:
--   trigger: The text or Lua pattern that activates the snippet.
--   replacement: The inserted LaTeX/template text. Use [=[...]=] strings so backslashes
--     and [[0]] capture markers can be written without escaping.
--     [=[...]=] is Lua long-string syntax. The = signs are delimiter guards:
--     plain [[...]] would end too early when the text contains [[0]], while
--     [=[...]=] keeps [[0]] literal. More = signs can be added if needed, e.g.
--     [==[text containing [=[...]=]]==].
--   options: Latex Suite-style flags interpreted by latex_snippet_factory.lua.
--     m = active in math zones only.
--     t = active outside math zones only.
--     A = autosnippet; expands immediately when the trigger matches.
--     r = regex trigger; the trigger is a Lua pattern, not literal text.
--     M = treated like m for now.
--     Without A, expand manually with <Tab> when the cursor is after the trigger.
--   wordTrig: Optional LuaSnip word-boundary behavior.
--     Omit this for the default: literal triggers are word-triggered, regex triggers are not.
--     Set wordTrig = false for punctuation triggers like '+-' that should still expand.
--   priority: Optional LuaSnip priority. Higher values win when triggers overlap.
--   description/name: Optional completion/help text.
--   disabled = true: Keep an entry in the file without registering it.
--
-- Replacement markers:
--   $0, $1, $2: Insert/jump locations. Because LuaSnip reserves final jump 0,
--     these become LuaSnip jump nodes 1, 2, 3 internally.
--   ${0:default}: Insert/jump location with default text.
--   Repeated ${0:default} markers mirror the first value.
--   [[0]], [[1]]: Regex captures from the trigger, using Obsidian's zero-based style.
--   ${VISUAL}: Placeholder for selected text. Currently implemented as a normal
--     insert location; visual wrapping can be added later if needed.
--
-- Regex triggers use Lua patterns, not JavaScript regex:
--   %d = digit, %a = letter, %w = alphanumeric, %s = whitespace.
--   Captures use (...), for example [=[([A-Za-z])(%d)]=].
--   Escape pattern punctuation with %, for example %. for a literal dot.
--   Backreferences use %1, %2, for example [=[([A-Za-z])%1%1]=].
--   Use [=[...]=] for regex strings too, especially when they contain backslashes.
M.snippets = {
  -- Math delimiters
  { trigger = 'mk', replacement = [=[$$0$]=], options = 'tA' },
  { trigger = 'dm', replacement = [=[$$
$0
$$]=], options = 'tA' },

  -- Custom wrappers
  { trigger = [=[([^%s])over([^%s])]=], replacement = [=[\overset{[[0]]}{[[1]]}$0]=], options = 'rmA' },
  { trigger = [=[([A-Za-z])%1%1]=], replacement = [=[\mathcal{[[0]]}]=], options = 'rmA' },
  { trigger = [=[([^%s%[%]%(%){}]+)%1]=], replacement = [=[\mathbb{[[0]]}]=], options = 'rm' },
  { trigger = [=[([^%(%s$]+)hat]=], replacement = [=[\hat{[[0]]}]=], options = 'rmA' },
  { trigger = [=[([^%(%s$]+)vec]=], replacement = [=[\vec{[[0]]}]=], options = 'rmA' },
  { trigger = 'avg', replacement = [=[\avg{ $0 } $1]=], options = 'mA' },
  { trigger = 'pd', replacement = [=[\pd[$0]{ $1 } $2]=], options = 'mA' },
  { trigger = 'OO', replacement = [=[\mathcal{O}($0) $1]=], options = 'mA' },
  { trigger = 'const', replacement = [=[\text{const.} $0]=], options = 'mA' },
  { trigger = 'norm', replacement = [=[\norm{ $0 } $1]=], options = 'mA', priority = 1 },
  { trigger = 'Norm', replacement = [=[\Norm{ $0 } $1]=], options = 'mA', priority = 1 },
  { trigger = 'abs', replacement = [=[\abs{ $0 } $1]=], options = 'mA', priority = 1 },
  { trigger = 'Abs', replacement = [=[\Abs{ $0 } $1]=], options = 'mA', priority = 1 },
  { trigger = 'p', replacement = [=[\partial_{$0}$1]=], options = 'm', priority = 1 },

  -- Greek letters
  { trigger = '@a', replacement = [=[\alpha]=], options = 'mA' },
  { trigger = '@b', replacement = [=[\beta]=], options = 'mA' },
  { trigger = '@g', replacement = [=[\gamma]=], options = 'mA' },
  { trigger = '@G', replacement = [=[\Gamma]=], options = 'mA' },
  { trigger = '@d', replacement = [=[\delta]=], options = 'mA' },
  { trigger = '@D', replacement = [=[\Delta]=], options = 'mA' },
  { trigger = '@e', replacement = [=[\epsilon]=], options = 'mA' },
  { trigger = ':e', replacement = [=[\varepsilon]=], options = 'mA' },
  { trigger = '@z', replacement = [=[\zeta]=], options = 'mA' },
  { trigger = '@t', replacement = [=[\theta]=], options = 'mA' },
  { trigger = '@T', replacement = [=[\Theta]=], options = 'mA' },
  { trigger = ':t', replacement = [=[\vartheta]=], options = 'mA' },
  { trigger = '@i', replacement = [=[\iota]=], options = 'mA' },
  { trigger = '@k', replacement = [=[\kappa]=], options = 'mA' },
  { trigger = '@l', replacement = [=[\lambda]=], options = 'mA' },
  { trigger = '@L', replacement = [=[\Lambda]=], options = 'mA' },
  { trigger = '@s', replacement = [=[\sigma]=], options = 'mA' },
  { trigger = '@S', replacement = [=[\Sigma]=], options = 'mA' },
  { trigger = '@u', replacement = [=[\upsilon]=], options = 'mA' },
  { trigger = '@U', replacement = [=[\Upsilon]=], options = 'mA' },
  { trigger = '@o', replacement = [=[\omega]=], options = 'mA' },
  { trigger = '@O', replacement = [=[\Omega]=], options = 'mA' },
  { trigger = 'ome', replacement = [=[\omega]=], options = 'mA' },
  { trigger = 'Ome', replacement = [=[\Omega]=], options = 'mA' },
  { trigger = ':p', replacement = [=[\varphi]=], options = 'mA' },
  { trigger = '@p', replacement = [=[\phi]=], options = 'mA' },

  -- Text and basic operations
  { trigger = 'text', replacement = [=[\text{$0}$1]=], options = 'mA' },
  { trigger = '"', replacement = [=[\text{$0}$1]=], options = 'mA' },
  { trigger = 'sr', replacement = [=[^{2}]=], options = 'mA', wordTrig = false },
  { trigger = 'cb', replacement = [=[^{3}]=], options = 'mA', wordTrig = false },
  { trigger = 'rd', replacement = [=[^{$0}$1]=], options = 'mA', wordTrig = false },
  { trigger = '_', replacement = [=[_{$0}$1]=], options = 'mA' },
  { trigger = 'sts', replacement = [=[_\text{$0}]=], options = 'mA' },
  { trigger = 'sq', replacement = [=[\sqrt{ $0 }$1]=], options = 'mA' },
  { trigger = '//', replacement = [=[\frac{$0}{$1}$2]=], options = 'mA' },
  { trigger = 'ee', replacement = [=[e^{ $0 }$1]=], options = 'mA' },
  { trigger = 'invs', replacement = [=[^{-1}]=], options = 'mA', wordTrig = false },
  { trigger = [=[([%a%d])/([%a%d])]=], replacement = [=[\frac{[[0]]}{[[1]]}]=], options = 'rmA', description = 'Auto inline fraction' },
  { trigger = [=[([\%w_%}%]%)]+)/([\%w_%{%[%(%+%-%}%]%)]+)]=], replacement = [=[\frac{[[0]]}{[[1]]}]=], options = 'rm', description = 'Inline fraction' },
  { trigger = [=[([A-Za-z])(%d)]=], replacement = [=[[0]]_{[[1]]}]=], options = 'rmA', description = 'Auto letter subscript', priority = -1 },
  { trigger = [=[([^\\])exp]=], replacement = [=[[0]]\exp]=], options = 'rmA' },
  { trigger = [=[([^\\])log]=], replacement = [=[[0]]\log]=], options = 'rmA' },
  { trigger = [=[([^\\])ln]=], replacement = [=[[0]]\ln]=], options = 'rmA' },
  { trigger = 'conj', replacement = [=[^{*}]=], options = 'mA', wordTrig = false },
  { trigger = 'Re', replacement = [=[\mathrm{Re}]=], options = 'mA' },
  { trigger = 'Im', replacement = [=[\mathrm{Im}]=], options = 'mA' },
  { trigger = 'bf', replacement = [=[\mathbf{$0}]=], options = 'mA' },
  { trigger = 'rm', replacement = [=[\mathrm{$0}$1]=], options = 'mA' },

  -- Decorations
  { trigger = [=[([a-zA-Z])bar]=], replacement = [=[\bar{[[0]]}]=], options = 'rmA' },
  { trigger = [=[([a-zA-Z])dot]=], replacement = [=[\dot{[[0]]}]=], options = 'rmA', priority = -1 },
  { trigger = [=[([a-zA-Z])ddot]=], replacement = [=[\ddot{[[0]]}]=], options = 'rmA', priority = 1 },
  { trigger = [=[([a-zA-Z])tilde]=], replacement = [=[\tilde{[[0]]}]=], options = 'rmA' },
  { trigger = [=[([a-zA-Z])und]=], replacement = [=[\underline{[[0]]}]=], options = 'rmA' },
  { trigger = [=[([a-zA-Z]),%.]=], replacement = [=[\mathbf{[[0]]}]=], options = 'rmA' },
  { trigger = [=[([a-zA-Z])%.,]=], replacement = [=[\mathbf{[[0]]}]=], options = 'rmA' },
  { trigger = 'hat', replacement = [=[\hat{$0}$1]=], options = 'mA' },
  { trigger = 'bar', replacement = [=[\bar{$0}$1]=], options = 'mA' },
  { trigger = 'dot', replacement = [=[\dot{$0}$1]=], options = 'mA', priority = -1 },
  { trigger = 'ddot', replacement = [=[\ddot{$0}$1]=], options = 'mA' },
  { trigger = 'cdot', replacement = [=[\cdot]=], options = 'mA' },
  { trigger = 'tilde', replacement = [=[\tilde{$0}$1]=], options = 'mA' },
  { trigger = 'und', replacement = [=[\underline{$0}$1]=], options = 'mA' },
  { trigger = 'vec', replacement = [=[\vec{$0}$1]=], options = 'mA' },

  -- Common subscripts
  { trigger = [=[([A-Za-z])_(%d%d)]=], replacement = [=[[0]]_{[[1]]}]=], options = 'rmA' },
  { trigger = [=[\\hat{([A-Za-z])}(%d)]=], replacement = [=[\hat{[[0]]}_{[[1]]}]=], options = 'rmA' },
  { trigger = [=[\\vec{([A-Za-z])}(%d)]=], replacement = [=[\vec{[[0]]}_{[[1]]}]=], options = 'rmA' },
  { trigger = [=[\\mathbf{([A-Za-z])}(%d)]=], replacement = [=[\mathbf{[[0]]}_{[[1]]}]=], options = 'rmA' },
  { trigger = 'xnn', replacement = [=[x_{n}]=], options = 'mA' },
  { trigger = 'xii', replacement = [=[x_{i}]=], options = 'mA' },
  { trigger = 'xjj', replacement = [=[x_{j}]=], options = 'mA' },
  { trigger = 'xp1', replacement = [=[x_{n+1}]=], options = 'mA' },
  { trigger = 'ynn', replacement = [=[y_{n}]=], options = 'mA' },
  { trigger = 'yii', replacement = [=[y_{i}]=], options = 'mA' },
  { trigger = 'yjj', replacement = [=[y_{j}]=], options = 'mA' },

  -- Symbols and relations
  { trigger = 'ooo', replacement = [=[\infty]=], options = 'mA' },
  { trigger = 'sum', replacement = [=[\sum]=], options = 'mA' },
  { trigger = 'prod', replacement = [=[\prod]=], options = 'mA' },
  { trigger = [=[\sum]=], replacement = [=[\sum_{${0:i}=${1:1}}^{${2:N}} $3]=], options = 'm' },
  { trigger = [=[\prod]=], replacement = [=[\prod_{${0:i}=${1:1}}^{${2:N}} $3]=], options = 'm' },
  { trigger = 'lim', replacement = [=[\lim_{ ${0:n} \to ${1:\infty} } $2]=], options = 'mA' },
  { trigger = '+-', replacement = [=[\pm]=], options = 'mA', wordTrig = false },
  { trigger = '-+', replacement = [=[\mp]=], options = 'mA', wordTrig = false },
  { trigger = '...', replacement = [=[\dots]=], options = 'mA' },
  { trigger = 'nabl', replacement = [=[\nabla]=], options = 'mA' },
  { trigger = 'del', replacement = [=[\nabla]=], options = 'mA' },
  { trigger = 'xx', replacement = [=[\times]=], options = 'mA' },
  { trigger = '**', replacement = [=[\cdot]=], options = 'mA' },
  { trigger = 'para', replacement = [=[\parallel]=], options = 'mA' },
  { trigger = '===', replacement = [=[\equiv]=], options = 'mA' },
  { trigger = '!=', replacement = [=[\neq]=], options = 'mA' },
  { trigger = '>=', replacement = [=[\geq]=], options = 'mA' },
  { trigger = '<=', replacement = [=[\leq]=], options = 'mA' },
  { trigger = '>>', replacement = [=[\gg]=], options = 'mA' },
  { trigger = '<<', replacement = [=[\ll]=], options = 'mA' },
  { trigger = 'simm', replacement = [=[\sim]=], options = 'mA' },
  { trigger = 'sim=', replacement = [=[\simeq]=], options = 'mA' },
  { trigger = 'prop', replacement = [=[\propto]=], options = 'mA' },
  { trigger = '<->', replacement = [=[\leftrightarrow ]=], options = 'mA' },
  { trigger = '->', replacement = [=[\to]=], options = 'mA' },
  { trigger = '!>', replacement = [=[\mapsto]=], options = 'mA' },
  { trigger = '=>', replacement = [=[\implies]=], options = 'mA' },
  { trigger = '=<', replacement = [=[\impliedby]=], options = 'mA' },
  { trigger = 'and', replacement = [=[\cap]=], options = 'mA' },
  { trigger = 'orr', replacement = [=[\cup]=], options = 'mA' },
  { trigger = 'inn', replacement = [=[\in]=], options = 'mA' },
  { trigger = 'notin', replacement = [=[\not\in]=], options = 'mA' },
  { trigger = [=[\\\]=], replacement = [=[\setminus]=], options = 'mA' },
  { trigger = 'sub=', replacement = [=[\subseteq]=], options = 'mA' },
  { trigger = 'sup=', replacement = [=[\supseteq]=], options = 'mA' },
  { trigger = 'eset', replacement = [=[\emptyset]=], options = 'mA' },
  { trigger = 'set', replacement = [=[\{ $0 \}$1]=], options = 'mA' },
  { trigger = 'LL', replacement = [=[\mathcal{L}]=], options = 'mA' },
  { trigger = 'HH', replacement = [=[\mathcal{H}]=], options = 'mA' },
  { trigger = 'CC', replacement = [=[\mathbb{C}]=], options = 'mA' },
  { trigger = 'RR', replacement = [=[\mathbb{R}]=], options = 'mA' },
  { trigger = 'ZZ', replacement = [=[\mathbb{Z}]=], options = 'mA' },
  { trigger = 'NN', replacement = [=[\mathbb{N}]=], options = 'mA' },

  -- Derivatives and integrals
  { trigger = 'par', replacement = [=[\frac{ \partial ${0:y} }{ \partial ${1:x} } $2]=], options = 'm' },
  { trigger = [=[pa([A-Za-z])([A-Za-z])]=], replacement = [=[\frac{ \partial [[0]] }{ \partial [[1]] } ]=], options = 'rm' },
  { trigger = 'ddt', replacement = [=[\frac{d}{dt} ]=], options = 'mA' },
  { trigger = [=[([^\\])int]=], replacement = [=[[0]]\int]=], options = 'rmA', priority = -1 },
  { trigger = [=[\int]=], replacement = [=[\int $0 \, d${1:x} $2]=], options = 'm' },
  { trigger = 'dint', replacement = [=[\int_{${0:0}}^{${1:1}} $2 \, d${3:x} $4]=], options = 'mA' },
  { trigger = 'oint', replacement = [=[\oint]=], options = 'mA' },
  { trigger = 'iint', replacement = [=[\iint]=], options = 'mA' },
  { trigger = 'iiint', replacement = [=[\iiint]=], options = 'mA' },
  { trigger = 'oinf', replacement = [=[\int_{0}^{\infty} $0 \, d${1:x} $2]=], options = 'mA' },
  { trigger = 'infi', replacement = [=[\int_{-\infty}^{\infty} d${1:x} ~ $0]=], options = 'mA' },

  -- Trig and linear algebra
  { trigger = [=[([^\\])sin]=], replacement = [=[[0]]\sin]=], options = 'rmA' },
  { trigger = [=[([^\\])cos]=], replacement = [=[[0]]\cos]=], options = 'rmA' },
  { trigger = [=[([^\\])tan]=], replacement = [=[[0]]\tan]=], options = 'rmA' },
  { trigger = [=[([^\\])det]=], replacement = [=[[0]]\det]=], options = 'rmA' },
  { trigger = 'trace', replacement = [=[\mathrm{Tr}]=], options = 'mA' },

  -- Physics and quantum mechanics
  { trigger = 'kbt', replacement = [=[k_{B}T]=], options = 'mA' },
  { trigger = 'msun', replacement = [=[M_{\odot}]=], options = 'mA' },
  { trigger = 'dag', replacement = [=[^{\dagger}]=], options = 'mA' },
  { trigger = 'o+', replacement = [=[\oplus ]=], options = 'mA' },
  { trigger = 'ox', replacement = [=[\otimes ]=], options = 'mA' },
  { trigger = 'bra', replacement = [=[\bra{$0} $1]=], options = 'mA' },
  { trigger = 'ket', replacement = [=[\ket{$0} $1]=], options = 'mA' },
  { trigger = 'brk', replacement = [=[\braket{ $0 | $1 } $2]=], options = 'mA' },
  { trigger = 'outer', replacement = [=[\ket{${0:\psi}} \bra{${0:\psi}} $1]=], options = 'mA' },

  -- Chemistry
  { trigger = 'pu', replacement = [=[\pu{ $0 }]=], options = 'mA' },
  { trigger = 'cee', replacement = [=[\ce{ $0 }]=], options = 'mA' },
  { trigger = 'he4', replacement = [=[{}^{4}_{2}He ]=], options = 'mA' },
  { trigger = 'he3', replacement = [=[{}^{3}_{2}He ]=], options = 'mA' },
  { trigger = 'iso', replacement = [=[{}^{${0:4}}_{${1:2}}${2:He}]=], options = 'mA' },

  -- Environments
  { trigger = 'beg', replacement = [=[\begin{$0}
$1
\end{$0}]=], options = 'mA' },
  { trigger = 'pmat', replacement = [=[\begin{pmatrix}
$0
\end{pmatrix}]=], options = 'mA' },
  { trigger = 'bmat', replacement = [=[\begin{bmatrix}
$0
\end{bmatrix}]=], options = 'mA' },
  { trigger = 'Bmat', replacement = [=[\begin{Bmatrix}
$0
\end{Bmatrix}]=], options = 'mA' },
  { trigger = 'vmat', replacement = [=[\begin{vmatrix}
$0
\end{vmatrix}]=], options = 'mA' },
  { trigger = 'Vmat', replacement = [=[\begin{Vmatrix}
$0
\end{Vmatrix}]=], options = 'mA' },
  { trigger = 'matrix', replacement = [=[\begin{matrix}
$0
\end{matrix}]=], options = 'mA' },
  { trigger = 'cases', replacement = [=[\begin{cases}
$0
\end{cases}]=], options = 'mA' },
  { trigger = 'align', replacement = [=[\begin{align}
$0
\end{align}]=], options = 'mA' },
  { trigger = 'array', replacement = [=[\begin{array}
$0
\end{array}]=], options = 'mA' },

  -- Brackets
  { trigger = 'ceil', replacement = [=[\lceil $0 \rceil $1]=], options = 'mA' },
  { trigger = 'floor', replacement = [=[\lfloor $0 \rfloor $1]=], options = 'mA' },
  { trigger = 'mod', replacement = [=[|$0|$1]=], options = 'mA' },
  { trigger = 'lr(', replacement = [=[\left( $0 \right) $1]=], options = 'mA' },
  { trigger = 'lr{', replacement = [=[\left\{ $0 \right\} $1]=], options = 'mA' },
  { trigger = 'lr[', replacement = [=[\left[ $0 \right] $1]=], options = 'mA' },
  { trigger = 'lr|', replacement = [=[\left| $0 \right| $1]=], options = 'mA' },
  { trigger = 'lra', replacement = [=[\left< $0 \right> $1]=], options = 'mA' },

  -- Misc
  {
    trigger = 'tayl',
    replacement = [=[${0:f}(${1:x} + ${2:h}) = ${0:f}(${1:x}) + ${0:f}'(${1:x})${2:h} + ${0:f}''(${1:x}) \frac{${2:h}^{2}}{2!} + \dots$3]=],
    options = 'mA',
    description = 'Taylor expansion',
  },
}

return M
