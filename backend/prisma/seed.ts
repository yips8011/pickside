import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

/**
 * 初始化演示数据
 *
 * - 管理员：admin / SUPER_ADMIN
 * - 普通用户：demo
 * - 两条示例投票
 *
 * 密码通过环境变量 SEED_PASSWORD 指定；未设置时使用内置演示密码。
 * 演示密码仅用于本地开发，请在首次登录后立即修改。
 */
const prisma = new PrismaClient();

const SEED_PASSWORD = process.env.SEED_PASSWORD ?? 'seed-password';

async function main() {
  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 12);

  const admin = await prisma.user.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      uid: 100001,
      username: 'admin',
      passwordHash,
      nickname: '社区管理员',
      role: UserRole.SUPER_ADMIN,
      bio: '维护社区秩序，处理举报和审核。',
    },
  });

  const user = await prisma.user.upsert({
    where: { username: 'demo' },
    update: {},
    create: {
      uid: 100002,
      username: 'demo',
      passwordHash,
      nickname: '演示用户',
      bio: '喜欢用投票看见群体选择。',
    },
  });

  const existingPoll = await prisma.poll.findFirst({
    where: { title: '第一版社区应该优先优化什么？' },
  });

  if (!existingPoll) {
    await prisma.poll.create({
      data: {
        title: '第一版社区应该优先优化什么？',
        description: '小规模上线测试时，哪一项最影响你是否愿意留下来？',
        authorId: admin.id,
        endAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        voteCount: 91,
        commentCount: 1,
        likeCount: 19,
        favoriteCount: 7,
        viewCount: 328,
        options: {
          create: [
            { text: '投票体验', color: '#4F46E5', sortOrder: 0, voteCount: 42 },
            { text: '评论氛围', color: '#059669', sortOrder: 1, voteCount: 31 },
            { text: '推荐质量', color: '#EA580C', sortOrder: 2, voteCount: 18 },
          ],
        },
        comments: {
          create: {
            authorId: user.id,
            content: '投完马上看到比例会很爽，但评论区也要干净。',
            likeCount: 8,
          },
        },
      },
    });

    await prisma.poll.create({
      data: {
        title: '热点话题是否应该默认开启匿名评论？',
        description: '匿名能降低表达门槛，也可能提高管理成本。',
        authorId: user.id,
        isAnonymous: true,
        allowShare: false,
        endAt: new Date(Date.now() + 20 * 60 * 60 * 1000),
        voteCount: 121,
        likeCount: 33,
        favoriteCount: 11,
        viewCount: 592,
        options: {
          create: [
            { text: '应该默认开启', color: '#DB2777', sortOrder: 0, voteCount: 64 },
            { text: '应该手动开启', color: '#0891B2', sortOrder: 1, voteCount: 57 },
          ],
        },
      },
    });
  }

  console.log(`
✅ 演示数据初始化完成
   管理员：admin
   普通用户：demo
   密码：${process.env.SEED_PASSWORD ? '（来自 SEED_PASSWORD 环境变量）' : SEED_PASSWORD}
   ⚠️  请在首次登录后立即修改密码
`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
