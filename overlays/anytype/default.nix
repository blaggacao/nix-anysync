{ final, prev }:

{
  # Override anytype-heart from nixpkgs with the patch from PR #3220
  # https://patch-diff.githubusercontent.com/raw/anyproto/anytype-heart/pull/3220.patch
  anytype-heart = prev.anytype-heart.overrideAttrs (oldAttrs: rec {
    version = "0.50.17";
    src = final.fetchFromGitHub {
      owner = "anyproto";
      repo = "anytype-heart";
      tag = "v${version}";
      sha256 = "sha256-2DXYpBc14z+q+kJNLScWSTqVSObolj/80FrVEwNU4cY=";
    };
    patches = (oldAttrs.patches or [ ]) ++ [
      (final.fetchurl {
        url = "https://patch-diff.githubusercontent.com/raw/anyproto/anytype-heart/pull/3220.patch";
        hash = "sha256-c+WtZitImfryzjAKI3hmIfjfKFLIO7A85osoTkIJZp8=";
      })
    ];
  });

  # Override anytype-cli from nixpkgs to use v0.3.6 instead of v0.3.5
  anytype-cli = prev.anytype-cli.overrideAttrs (oldAttrs: rec {
    version = "0.3.6";
    src = final.fetchFromGitHub {
      owner = "anyproto";
      repo = "anytype-cli";
      tag = "v${version}";
      sha256 = "sha256-T/mdF+pzApm15Cg2g1ybgU7pEHLsTC4jD7WuXzNqM2M=";
    };
    vendorHash = "sha256-S6Xb2XYAn/cTC++1WK5cmXcC6QCZpPoYMRrjk/IPKas=";
  });
}
