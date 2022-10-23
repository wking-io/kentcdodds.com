import {json} from '@remix-run/node'

export async function loader() {
  const mdxBundler = await import('mdx-bundler')
  const mdxSource = `
---
title: Example Post
published: 2021-02-13
description: This is some description
---

# Wahoo

import Demo from './demo'

Here's a **neat** demo:

<Demo />
`.trim()

  const result = await mdxBundler.bundleMDX({
    source: mdxSource,
    files: {
      './demo.tsx': `
import * as React from 'react'

function Demo() {
  return <div>Neat demo!</div>
}

export default Demo
    `.trim(),
    },
  })
  return json(result)
}
