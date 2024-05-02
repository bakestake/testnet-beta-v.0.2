/* eslint-disable */
/* prettier-ignore */
const chainFacetSelectorsKeys = [
    "0x63c5f208",
    "0xfd2b5202",
    "0xfb813d43",
    "0x372500ab",
    "0x150b7a02",
    "0x2f914df2",
    "0xba932e98",
    "0xa0b966ce"
];

/* prettier-ignore */
const crossChainFacetSelectorKeys = [
    "0x58193822",
    "0xad3cb1cc",
    "0x95fa8b8e",
    "0x180dcecc",
    "0xf6dc2292",
    "0xff7bd03d",
    "0xab748516",
    "0x5e280f11",
    "0x82413eac",
    "0x13137d65",
    "0x7d25a05e",
    "0x17442b70",
    "0x8da5cb5b",
    "0xbb0b6a53",
    "0x52d1902d",
    "0x715018a6",
    "0xca5eb5e1",
    "0x3400288b",
    "0xf2fde38b",
    "0x4f1ef286"
];

/* prettier-ignore */
const diamondLoupeSelector = [
	"0xcdffacc6",
	"0x52ef6b2c",
	"0xadfca15e",
	"0x7a0ed627",
	"0x01ffc9a7"
]

/* prettier-ignore */
const getterSetterSelector = [
	"0x658b6729",
	"0x4269e94c",
	"0x25970f6d",
	"0xadb73624",
	"0xe2197110",
	"0xf0f44260"
]

export const getSelector = (contractName: string) => {
  switch (contractName) {
    case "ChainFacet":
      return chainFacetSelectorsKeys;
    case "CrossChainFacet":
      return crossChainFacetSelectorKeys;
    case "DiamondLoupe":
      return diamondLoupeSelector;
    case "GetterSetter":
      return getterSetterSelector;
    default:
      break;
  }
};
