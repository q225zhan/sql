#The student number and name of second year students who have obtained
#a grade lower than 65 in at least two first year computer science (CS)
#courses.
select distinct s.snum, s.sname
from student s
where s.year = 2
and exists (
    select *
    from mark m1, mark m2
    where s.snum = m1.snum
    and s.snum = m2.snum
    and m1.cnum <> m2.cnum
    and m1.cnum like 'CS1%'
    and m2.cnum like 'CS1%'
    and m1.grade < 65
    and m2.grade < 65);

#The number and name of professors who are not in the PM department
#and who are teaching CS245 for the first time.
select distinct p.pnum, p.pname
from professor p
where p.dept <> “PM”
and exist (select * from class c1
     where c1.pnum=p.pnum
     and c1.cnum=”CS245”
     and not exist (select * from mark m
 where m.cnum=c1.cnum
 and m.term=c1.term
 and m.section=c1.section)
 and not exist (select * from class c2
                        where c2.cnum=”CS245”
                        and c2.pnum=p.pnum
                        and c2.term <> c1.term)
)


#The number, name and year of students who have obtained a grade in
#CS240 that is within 5 marks of the highest ever grades recorded for that
#course.
select distinct s.snum, s.sname, s.year
from mark m, student s
where 
  m.snum = s.snum
  and m.cnum = 'CS240' 
  and m.grade >= (select m1.grade - 5 as threshold
    from mark m1
    where m1.cnum = 'CS240' 
      and not exists(select * from mark m2
        where m2.cnum = m1.cnum
          and m2.grade > m1.grade));


#The number and name of students who have completed two years, who
#have a final grade of at least 85 in every computer science course that
#they have taken, and who have never been taught by a professor in the
#combinatorics and optimization (CO) department.
SELECT DISTINCT s.snum, s.sname 
FROM student s 
WHERE s.year > 2 
AND s.snum NOT IN (SELECT DISTINCT m.snum 
                   FROM mark m 
                   WHERE m.grade < 85 
                   AND m.cnum LIKE 'CS%') 
AND s.snum NOT IN (SELECT DISTINCT e.snum 
                   FROM enrollment e, class c, professor p 
                   WHERE p.dept = 'CO' 
                   AND c.cnum = e.cnum 
                   AND c.term = e.term  
                   AND c.section = e.section
                   AND c.pnum = p.pnum)


#A sorted list of all departments who have a professor who is currently
#teaching on Mondays before noon and on Fridays after noon.
select distinct p.dept
from professor p
where exists (
      select *
      from class cl, schedule sch
      where cl.pnum = p.pnum
      and cl.cnum = sch.cnum
      and cl.term = sch.term
      and cl.section = sch.section
      and ((sch.day = 'Friday' and sch.time > '12:00') or (sch.day = 'Monday' and sch.time < '12:00'))
      and not exists (
          select *
          from mark m
          where m.cnum = cl.cnum
          and m.term = cl.term
          and m.section = cl.section))
order by p.dept;

#The ratio of professors in pure math to professors in computer science who
#have taught a class in which the lowest grade obtained in the class was
#less than 65
WITH LowMarkProf(pnum)
AS (SELECT DISTINCT c.pnum
    FROM class c, mark m
    WHERE c.cnum = m.cnum
    AND c.term = m.term
    AND c.section = m.section
    AND m.grade < 65)
SELECT COUNT (DISTINCT p.pnum) * 1.0 /
(SELECT COUNT (DISTINCT p.pnum)
 FROM professor p
 WHERE p.dept = 'CS'
 AND p.pnum IN (SELECT pnum FROM LowMarkProf))
AS ratio
FROM professor p
WHERE p.dept = 'PM'
AND p.pnum IN (SELECT pnum FROM LowMarkProf)

#The number, name and department of professors together with the average
#enrollment count and average final grade for each course that they have
#taught. (In the case of professors who have never taught a course, the
#average enrollment count and average final grade should be zero.)
with T as(
  select distinct p.pnum as pnum, p.pname as pname, p.dept as pdept, count(*) as ecmt, avg(m.grade) as avg_grade
  from professor p, class cl, mark m
  where p.pnum = cl.pnum
    and cl.cnum = m.cnum
    and cl.term = m.term
    and cl.section = m.section
    group by p.pnum, p.pname, p.dept, cl.cnum)
select distinct t.pnum, t.pname, t.pdept, avg(t.ecmt) as enroll_count, avg(t.avg_grade) as avg_final_grade
from T t
group by t.pnum, t.pname, t.pdept, t.pnum;

#The number of different students in each term for a course that has been
#taught by either a computer science (CS) or pure math (PM) professor.
#Each result should include a department, a course number, a term and
#said count, and should also be sorted in a descending order by the said
#count.
SELECT DISTINCT p.dept, c.cnum, c.term, COUNT (DISTINCT e.snum) AS num
FROM professor p, class c, enrollment e  
WHERE e.cnum = c.cnum
AND e.term = c.term
AND e.section = c.section
AND c.pnum = p.pnum
AND p.dept = 'CS' OR p.dept = 'PM'
GROUP BY p.dept, c.cnum, c.term
ORDER BY num desc

#The minimum and maximum final grade for each class taught in the past
#on either Mondays or Fridays by a professor in the computer science department.
#The result should include the number and name of the professor,
#and the course name and primary key of the class.
select p.pnum, p.pname, s.cname, c.cnum, c.term, c.section, min(m.grade) as min_grade, max(m.grade) as max_grade
 from professor p, class c, schedule h, course s, mark m
 where p.dept = 'CS'
    and c.pnum = p.pnum
    and h.cnum = c.cnum
    and h.term = c.term
    and h.section = c.section
    and (h.day = 'Monday' or h.day = 'Friday')
    and s.cnum = c.cnum
    and m.cnum = c.cnum
    and m.term = c.term
    and m.section = c.section
 group by p.pnum, p.pname, s.cname, c.cnum, c.term, c.section;

#The percentage of professors in computer science who are neither currently
#teaching nor have ever taught in the past two classes for two different
#courses in the same term.
select distinct count(distinct p.pnum)/(select count(*) from professor p where p.dept=”CS”)
from professor p
where p.dept=”CS”
and p.pnum not in
(select pp.pnum
 from class c1, class  c2. professor pp
where c1.pnum=pp.pnum
                and c2.pnum=pp.pnum
               and c1.term=c2.term
               and c1.term !=”W2017”
               and c1.cnum != c2.cnum
              and pp.dept=”CS”)
and p.pnum not in
(select pnum from class where term=”W2017”)

