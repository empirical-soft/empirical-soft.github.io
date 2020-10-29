## Empirical Website

This is the source for [empirical-soft.com](https://www.empirical-soft.com). It uses [Jekyll](https://jekyllrb.com) to generate the site from the included [Markdown](https://jekyllrb.com/docs/configuration/markdown/) files. Hosting is provided by [GitHub Pages](https://pages.github.com).

To build the website and start a server locally:

```
$ make
```

When finished:

```
$ make clean
```

Uploading changes via git will automatically build the website, so pushed commits go live immediately.

----

### Publishing a blog entry

Make a copy of `_drafts/sample.md` and edit away. Then run:

```
./publish.sh _drafts/my_post.md
```

See Jekyll's [notes](https://jekyllrb.com/docs/posts/) for more info.
