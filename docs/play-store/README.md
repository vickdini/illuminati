# Publishing Illuminati on Google Play

Everything needed for the Play Console, ready to copy. Graphics are in this
folder; the app bundle is built by the GitHub workflow.

## 1. Before the listing

1. **Developer account:** sign up at <https://play.google.com/console/signup>
   (one-time US$25 fee, identity verification, and for a personal account a
   verified Android phone).
2. **Testing requirement:** personal accounts created after November 2023
   must run a **closed test with at least 12 testers for 14 days** before
   they can apply for production access. Plan for this.
3. **Create the app:** Play Console → **Create app**
   - App name: `Illuminati: Free Classic Books`
   - Default language: English (United States) – en-US
   - App or game: **App** · Free or paid: **Free**

## 2. App bundle and signing

- Download `play-store-bundle` (`Illuminati-play.aab`) from the latest
  GitHub Actions run (Actions tab → run → Artifacts).
- It is signed with the project's own key (`illuminati-release.jks`), which
  becomes the **upload key**. When Play asks about **app signing**, keep
  **Google-generated key** (recommended). Note: Play then re-signs the app
  with Google's key, so the Play version and the APK from GitHub can't be
  installed over each other; users should pick one.
- This build has no in-app updater (Play doesn't allow it) and doesn't ask
  for the "install unknown apps" permission.
- Each upload needs a higher version code; the workflow uses the run number
  (+100), so any newer run's bundle works.

## 3. Store listing

**App name** (30 max): `Illuminati: Free Classic Books`

**Short description** (80 max):

```
75,000+ free classic books. Read offline, highlight, translate. No ads, no account.
```

**Full description** (4,000 max):

```
Read the world's great books for free.

Illuminati gathers more than 75,000 public-domain books from four of the best free libraries, Project Gutenberg, Standard Ebooks, Wikisource and the Internet Archive, and gives you a calm, beautiful place to read them. Austen, Dostoevsky, Mary Shelley, Dickens, Marcus Aurelius, Jane Eyre, Moby-Dick, Sherlock Holmes: all free, all legal, all yours to keep.

FIND YOUR NEXT BOOK
• Search every library at once by title or author
• Browse by category: fiction, mystery, science fiction, poetry, philosophy, history and more
• Filter by language, or explore books in many languages
• Get illustrated editions when they exist

READ COMFORTABLY
• Download once and read offline, anywhere
• Pick up exactly where you left off
• See how many minutes are left in the chapter, based on your own reading speed
• Light, sepia and dark themes
• Four beautiful fonts, including Literata, EB Garamond, Atkinson Hyperlegible and OpenDyslexic for readers with dyslexia
• Adjust text size, line spacing, letter spacing, margins and line width
• Brightness and warmth controls for reading at night

MAKE EACH BOOK YOURS
• Highlight passages in four colours and add your own notes
• Bookmark pages and jump back to them
• Search inside any book
• Look up words in the dictionary and translate passages without leaving the page
• Copy all your highlights and notes in one tap

ORGANISE YOUR LIBRARY
• Want to read, Reading and Finished lists
• Create your own shelves: Favourites, Philosophy, Summer reading…
• Sort by recently read, title, author or progress

PRIVATE BY DESIGN
• No account, no ads, no tracking
• Your library, notes and settings stay on your device

The interface is available in English, Spanish, French, German, Italian and Portuguese.

All books are in the public domain in the United States; copyright terms differ between countries, so check your local laws before downloading.
```

**Graphics** (this folder):

| Asset | File |
|---|---|
| App icon, 512 × 512 | `icon-512.png` |
| Feature graphic, 1024 × 500 | `feature-graphic-1024x500.png` |
| Phone screenshots, 1080 × 1920 (upload in this order) | `screenshots/01-home.png` … `06-dark.png` |

**Category:** Books & Reference · **Tags:** Books, E-readers, Literature

**Contact details:** an email address is required (shown publicly on the
listing). Website: `https://github.com/vickdini/illuminati`

**Privacy policy URL:**
`https://github.com/vickdini/illuminati/blob/main/PRIVACY.md`

## 4. App content (Policy → App content)

| Section | Answer |
|---|---|
| Privacy policy | The URL above |
| Ads | **No**, the app doesn't contain ads |
| App access | **All functionality is available without special access** |
| Content rating | Questionnaire category: **Reference, News, or Educational**. Answer **No** to violence, sexuality, offensive language, drugs and gambling, and **No** to user interaction, sharing location and digital purchases. If asked about unrestricted internet access, answer **No**: the app shows books from fixed libraries and isn't a web browser. |
| Target audience | **18 and over** (or 13+). Don't select children's ages: the catalogues include adult literature, and the app isn't designed for children. |
| News app | **No** |
| Data safety | See below |
| Government app | **No** |
| Financial features | **None** |
| Health | **None** |

### Data safety answers

- **Does your app collect or share any of the required user data types?**
  **No.** The app has no server and stores nothing off the device. Search
  words and selected text go straight from the device to the library,
  Wiktionary or MyMemory only when the user asks for that action, are used
  only to answer it, and aren't linked to any identity; Google's guidance
  treats such user-initiated, ephemeral requests as not collected or shared.
  If you'd rather be conservative, declare **App activity → Other
  user-generated content** as *collected*, *not shared*, *processed
  ephemerally*, *optional*, purpose **App functionality**.
- **Is all of the user data collected by your app encrypted in transit?**
  Yes (all requests use HTTPS).
- **Do you provide a way for users to request that their data is deleted?**
  Not applicable: no data leaves the device; uninstalling deletes it.

## 5. Release

1. **Testing → Closed testing → Create track**, add your testers' Google
   accounts (12+), upload `Illuminati-play.aab`, write release notes, and
   roll out.
2. After 14 days with 12+ opted-in testers, apply for **production access**
   (Dashboard), answer the short questionnaire, and once approved create a
   production release with the same bundle or a newer one.

Release notes example:

```
First release on Google Play: 75,000+ free classic books, offline reading, highlights and notes, dictionary and translation, six languages, and no ads or account.
```
