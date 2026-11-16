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

@Entity("favorite")
@Index("uk_favorite_member_movie", ["member", "movieId"], { unique: true })
export class Favorite extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: "favorite_id", type: "bigint" })
  favoriteId: number;

  @ManyToOne(() => Member, { nullable: false, onDelete: "RESTRICT" })
  @JoinColumn({ name: "member_id" })
  member: Relation<Member>;

  // TMDB identifier. There is no local movie table.
  @Column({ name: "movie_id", type: "bigint" })
  movieId: number;
}
