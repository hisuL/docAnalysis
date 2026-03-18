-- Conversation Orchestrator 数据库初始化脚本
-- 版本: 1.0.0
-- 日期: 2026-03-17
--
-- 使用说明：
-- 按顺序执行以下 SQL 文件：
-- 1. sql/schema.sql - 创建 Schema
-- 2. sql/sessions.sql - 创建会话表
-- 3. sql/conversations.sql - 创建对话历史表
-- 4. sql/summaries.sql - 创建文档摘要表
-- 5. sql/feedbacks.sql - 创建反馈表
-- 6. sql/triggers.sql - 创建触发器
--
-- 或者直接执行本文件（包含所有内容）

\i sql/schema.sql
\i sql/sessions.sql
\i sql/conversations.sql
\i sql/summaries.sql
\i sql/feedbacks.sql
\i sql/triggers.sql
