import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";
import { BaseTimeEntity } from "./base-time.entity";

@Entity("member")
export class Member extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: "member_id", type: "bigint" })
  memberId: number;

  @Column({ type: "varchar", length: 254, unique: true })
  email: string;

  @Column({ type: "varchar", length: 60, select: false })
  password: string;

  @Column({ type: "varchar", length: 50, unique: true })
  nickname: string;
}
