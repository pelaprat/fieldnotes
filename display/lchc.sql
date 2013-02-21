create table kidCorrection (
  id    INT NOT NULL AUTO_INCREMENT,
  token VARCHAR(255) NOT NULL,
  PRIMARY KEY( id )
) Type = InnoDB;

create table jmCorrection (
  token     VARCHAR(255) NOT NULL,
  converted VARCHAR(255) NOT NULL,
  PRIMARY KEY(token, converted)
) Type = InnoDB;

/************************|
/** LCHC Global Tables **|
/************************|
create table t_person (
  id         INT NOT NULL AUTO_INCREMENT,
  first      VARCHAR(50) NOT NULL,
  middle     VARCHAR(50),
  last       VARCHAR(50) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  pass       VARCHAR(255) NOT NULL,
  admin      TINYINT(1) NOT NULL DEFAULT 0,
  instructor TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY(id)
) Type=InnoDB;

/*******************************|
/** Fieldnote Database Tables **|
/*******************************|
create table tn_course (
  id         INT NOT NULL AUTO_INCREMENT,
  instructor INT NOT NULL REFERENCES t_person(id),
  program    VARCHAR(4) NOT NULL,
  number     INT(3) NOT NULL,
  name       VARCHAR(255) NOT NULL,
  quarter    VARCHAR(6) NOT NULL,
  year       YEAR NOT NULL,
  current    TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY(id)
) Type=InnoDB;

create table tn_conference (
  id        INT NOT NULL AUTO_INCREMENT,
  course    INT NOT NULL REFERENCES tn_course(id),
  name      VARCHAR(255) NOT NULL,
  fieldnote TINYINT(1) NOT NULL DEFAULT 0,
  items     INT NOT NULL DEFAULT 0,
  PRIMARY KEY(id)
) Type=InnoDB;

/************************|
/** Virtual FTP Tables **|
/************************|
create table tvSpace (
  id     INT NOT NULL AUTO_INCREMENT,
  name   VARCHAR(255) NOT NULL,
  parent INT NOT NULL REFERENCES tv_space (id),
  path   VARCHAR(255) NOT NULL,
  server TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY(id)
) Type=InnoDB;

create table tvFile (
  id         INT NOT NULL AUTO_INCREMENT,
  name       VARCHAR(255),
  author     INT NOT NULL REFERENCES tv_person (id),
  space      INT NOT NULL REFERENCES tv_space  (id),
  timestamp  DATETIME NOT NULL,
  type       VARCHAR(30),
  ext        VARCHAR(4),
  bytes      INT NOT NULL DEFAULT 0,
  path       VARCHAR(255) DEFAULT '',
  historical TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
) TYPE=InnoDB;

/****************|
/* Joint Tables *|
/****************|
create table tCourseSpace (
  course INT NOT NULL REFERENCES tn_course(id),
  space  INT NOT NULL REFERENCES tv_space(id),
  PRIMARY KEY(course, space)
) Type=InnoDB;

create table tnCourseActivity (
  course   INT NOT NULL REFERENCES tn_course(id),
  activity INT NOT NULL REFERENCES t_activity(id),
  PRIMARY KEY(course, activity)
) Type=InnoDB;

create table tnCourseKid (
  course INT NOT NULL REFERENCES tn_course(id),
  kid    INT NOT NULL REFERENCES t_kid(id),
  PRIMARY KEY(course, kid)
) Type=InnoDB;

create table tnPersonCourse (
  person INT NOT NULL REFERENCES tn_person(id),
  course INT NOT NULL REFERENCES tn_course(id),
  PRIMARY KEY(person, course)
) Type=InnoDB;

create table tnSiteActivity (
  site     INT NOT NULL REFERENCES t_site(id),
  activity INT NOT NULL REFERENCES t_activity(id),
  PRIMARY KEY(site, activity)
) TYPE=InnoDB;


