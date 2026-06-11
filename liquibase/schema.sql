-- SPDX-FileCopyrightText: Copyright (c) 2019-2026 Yegor Bugayenko
-- SPDX-License-Identifier: MIT
--
-- Database schema for 0rsk (Online Risk Manager).
-- Auto-generated from liquibase/2019/ changesets 001-013.
-- For reference only. Actual DDL is managed by Liquibase.

CREATE TABLE project (
  id SERIAL PRIMARY KEY,
  login VARCHAR(64) NOT NULL,
  title VARCHAR(64) NOT NULL,
  created TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(login, title)
);
CREATE INDEX idx_project1 ON project (login);

CREATE TYPE ptype AS ENUM ('Cause', 'Risk', 'Effect', 'Plan');

CREATE TABLE part (
  id SERIAL PRIMARY KEY,
  project INT NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  type ptype NOT NULL,
  text VARCHAR(160) NOT NULL,
  created TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(project, text),
  CHECK (text <> '')
);
CREATE INDEX idx_part1 ON part (project, created);

CREATE TABLE cause (
  id INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
  emoji CHAR DEFAULT '💾' NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE risk (
  id INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
  probability INT NOT NULL DEFAULT 4,
  PRIMARY KEY (id),
  CHECK (probability >= 1),
  CHECK (probability <= 9)
);
CREATE INDEX idx_risk1 ON risk (probability);

CREATE TABLE effect (
  id INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
  impact INT NOT NULL DEFAULT 4,
  positive BOOLEAN DEFAULT false NOT NULL,
  PRIMARY KEY (id),
  CHECK (impact >= 1),
  CHECK (impact <= 9)
);
CREATE INDEX idx_effect1 ON effect (impact);

CREATE TABLE plan (
  id INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
  part INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
  schedule VARCHAR(32) NOT NULL DEFAULT 'weekly',
  completed TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (id, part),
  CHECK (schedule <> '')
);
CREATE INDEX idx_plan1 ON plan (part);

CREATE TABLE triple (
  id SERIAL PRIMARY KEY,
  cause INT NOT NULL REFERENCES cause(id) ON DELETE CASCADE,
  risk INT NOT NULL REFERENCES risk(id) ON DELETE CASCADE,
  effect INT NOT NULL REFERENCES effect(id) ON DELETE CASCADE,
  created TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (cause, risk, effect)
);
CREATE INDEX idx_triple1 ON triple (cause, risk, effect);

CREATE TABLE task (
  id SERIAL PRIMARY KEY,
  plan INT NOT NULL REFERENCES part(id) ON DELETE CASCADE,
  created TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (plan)
);
CREATE INDEX idx_task1 ON task (plan);

CREATE TABLE telechat (
  id SERIAL PRIMARY KEY,
  login VARCHAR(64) NOT NULL,
  created TIMESTAMPTZ DEFAULT now() NOT NULL,
  recent TEXT DEFAULT '' NOT NULL,
  UNIQUE (login)
);
CREATE INDEX idx_telechat1 ON telechat (login);

CREATE TABLE teleping (
  id SERIAL PRIMARY KEY,
  task INT NOT NULL REFERENCES task(id) ON DELETE CASCADE,
  telechat INT NOT NULL REFERENCES telechat(id) ON DELETE CASCADE,
  updated TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE (task, telechat)
);
CREATE INDEX idx_teleping1 ON teleping (task);
CREATE INDEX idx_teleping2 ON teleping (updated);
