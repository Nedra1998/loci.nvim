## loci
This is the README for loci

### Components

#### Core

#### Telescope

### TODO

#### Core

- [x] Goto workspace index
  - `:LociWorkspace [WORKSPACE]`
- [ ] Goto journal index
  - `:LociJournalIndex [WORKSPACE] [JOURNAL]`
- [x] Goto journal shortcuts
  - `:LociJournalPrevious [WORKSPACE] [JOURNAL]`
  - `:LociJournalCurrent [WORKSPACE] [JOURNAL]`
  - `:LociJournalNext [WORKSPACE] [JOURNAL]`
  - `:LociJournal [WORKSPACE] [JOURNAL] [DATE]`
- [ ] Only create bindings for markdown files in a workspace.
- [x] Create link from text below cursor
  - `:LociLinkCreate`
- [-] Follow existing link below cursor
  - `:LociLinkFollow`
  - [x] Open URL in browser
  - [ ] Open external files with system default (`open`/`xdg-open`)
  - [x] Jump to section/achnor in file is specified in link
- [x] Follow link under cursor if present, otherwise create a new link.
  - `:LociLinkFollowOrCreate`
- [x] Go back to previous buffer on `:LociLinkGoBack`

#### Telescope

- [ ] Search for Note
- [ ] Search for Journal
- [ ] Search for link in current note
- [ ] Search for link to current note
- [ ] Search for notes with selected title

#### Smart Features

- [ ] Auto generate directory index
- [ ] Auto link to notes
  - [ ] Only link only the first occurance of the text
  - [ ] Don't create the link if a link exists later in the file
- [ ] Search for existing notes when creating a new link, and any notes
  matching the selected text will be used instead of creating a new note

#### Future

- [ ] Support formats other than Markdown?
