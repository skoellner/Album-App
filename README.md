# Only Albums

## Repo hygiene (Xcode + Cursor)

### Commit these
- `Only Albums.xcodeproj/project.pbxproj`
- `Only Albums/**/*.swift`
- `Only Albums/Assets.xcassets/**`
- `Only AlbumsTests/**`, `Only AlbumsUITests/**`

### Do not commit these
- Xcode user state: `**/xcuserdata/`, `**/*.xcuserstate`
- Build artifacts: `DerivedData/`, `build/`

### Lightweight Cursor workflow
- Keep changes small and scoped (ideally 1 intent per PR).
- In prompts, explicitly name the files you want edited and ask to avoid reformatting unrelated code.
- Review `git diff` before each commit.
- Build (and run tests if applicable) before pushing.
