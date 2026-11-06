import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  type Relation,
} from "typeorm";
import { BaseTimeEntity } from "./base-time.entity";
import { Member } from "./member.entity";

@Entity("rating")
@Index("uk_rating_member_movie", ["member", "movieId"], { unique: true })
export class Rating extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: "rating_id", type: "bigint" })
  ratingId: number;

  @ManyToOne(() => Member, { nullable: false, onDelete: "RESTRICT" })
  @JoinColumn({ name: "member_id" })
  member: Relation<Member>;

  // TMDB의 외부 식별자이며 로컬 영화 테이블의 FK가 아닙니다.
  @Column({ name: "movie_id", type: "bigint" })
  movieId: number;

  @Column({ type: "tinyint" })
  score: number;

  @Column({ type: "text", nullable: true })
  comment: string | null;
}
