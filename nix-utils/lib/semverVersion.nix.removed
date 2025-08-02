# This is a curried function: first provide the context, then the user-facing inputs.
{
  latestTag,
  currentBranch ? "main",
  currentSha ? "",
}: {
  current-version,
  detect-branch-builds ? "false",
}: let
  # Remove 'v' prefix if present
  stripV = v:
    if builtins.match "^v(.*)" v != null
    then (builtins.elemAt (builtins.match "^v(.*)" v) 0)
    else v;

  parseVersion = v: let
    parts = builtins.split "\\." v;
  in {
    major = builtins.elemAt parts 0;
    minor = builtins.elemAt parts 1;
    patch = builtins.elemAt parts 2;
  };

  current = parseVersion (stripV current-version);
  latest = parseVersion (stripV latestTag);

  # Compare major/minor
  majorChanged = current.major != latest.major;
  minorChanged = current.minor != latest.minor;

  # Patch bump logic
  newPatch = builtins.toString (builtins.fromJSON latest.patch + 1);

  semverVersion =
    if majorChanged || minorChanged
    then "${current.major}.${current.minor}.${current.patch}"
    else "${current.major}.${current.minor}.${newPatch}";

  # Branch build logic
  semverWithBranch =
    if detect-branch-builds == "true" && currentBranch != "main" && currentSha != ""
    then "${semverVersion}-${currentSha}"
    else semverVersion;
in {
  semver = semverWithBranch;
}
