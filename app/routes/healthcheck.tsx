import type {LoaderArgs} from '@remix-run/node'
import {prisma} from '~/utils/prisma.server'
import {getBlogReadRankings} from '~/utils/blog.server'

export async function loader({request}: LoaderArgs) {
  console.log(request.url, 'healthcheck loader')
  const host =
    request.headers.get('X-Forwarded-Host') ?? request.headers.get('host')

  console.log('would have made a host request', host)

  try {
    await Promise.all([
      prisma.user.count().then(r => console.log('healthecheck user count', r)),
      getBlogReadRankings({request}).then(r =>
        console.log('healthcheck blog', r),
      ),
      // fetch(`http://${host}`, {method: 'HEAD'}).then(async r => {
      //   if (!r.ok) {
      //     console.log('healthcheck fetch failure')
      //     return Promise.reject(r)
      //   }
      //   console.log('healthcheck fetch success')
      // }),
    ])
    console.log(request.url, 'healthcheck loader success')
    return new Response('OK')
  } catch (error: unknown) {
    console.log(request.url, 'healthcheck ❌', {error})
    return new Response('ERROR', {status: 500})
  }
}
