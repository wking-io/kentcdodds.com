import {json} from '@remix-run/node'
import {compileMdx} from '~/utils/compile-mdx.server'

export async function loader() {
  const result = await compileMdx('test-compile', [
    {
      path: 'test-compile/index.mdx',
      content: `---\ntitle: Test compile\n---\n\n# Test compile`,
    },
  ])
  return json(result)
}
