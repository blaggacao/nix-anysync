{ final, prev }:

{
  # Override anytype-heart from nixpkgs with the patch from PR #3220
  # https://patch-diff.githubusercontent.com/raw/anyproto/anytype-heart/pull/3220.patch
  anytype-heart = prev.anytype-heart.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (final.fetchurl {
        url = "https://patch-diff.githubusercontent.com/raw/anyproto/anytype-heart/pull/3220.patch";
        hash = "sha256-c+WtZitImfryzjAKI3hmIfjfKFLIO7A85osoTkIJZp8=";
      })
    ];
  });
}
