ALTER TABLE "Poll" ADD COLUMN "dislikeCount" INTEGER NOT NULL DEFAULT 0;

CREATE TABLE "PollDislike" (
  "id" SERIAL NOT NULL,
  "userId" INTEGER NOT NULL,
  "pollId" INTEGER NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PollDislike_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PollDislike_userId_pollId_key" ON "PollDislike"("userId", "pollId");
CREATE INDEX "PollDislike_pollId_idx" ON "PollDislike"("pollId");

ALTER TABLE "PollDislike" ADD CONSTRAINT "PollDislike_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PollDislike" ADD CONSTRAINT "PollDislike_pollId_fkey" FOREIGN KEY ("pollId") REFERENCES "Poll"("id") ON DELETE CASCADE ON UPDATE CASCADE;
