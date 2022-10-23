import type {LoaderArgs} from '@remix-run/node'
import {json} from '@remix-run/node'
import {getMdxPage} from '~/utils/mdx'

export async function loader({request}: LoaderArgs) {
  const page = await getMdxPage(
    {contentDir: 'blog', slug: 'migrating-to-jest'},
    {request},
  )
  return json(page)
}
