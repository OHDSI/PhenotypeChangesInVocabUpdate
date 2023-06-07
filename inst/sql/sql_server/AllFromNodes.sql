--1. get counts of standard and source concepts
--get the descendant_record_counts
create table #achilles_result_cc as 
with concept_cnt as (
select stratum_1 as concept_id, sum (count_value) as cnt-- in case a concept ends up in several tables by mistake we count all occurrences anyway
from @resultSchema.achilles_results ar where analysis_id in (
401, --	Number of condition occurrence records, by condition_concept_id
601,
701,
801,
1801, -- measurement_concept_id
2101 -- device
)
group by stratum_1
)
select a.concept_id, a.cnt as record_count, sum (d.cnt) as descendant_record_count from concept_cnt a
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id =a.concept_id
join concept_cnt d on d.concept_id = ca.descendant_concept_id 
group by a.concept_id, a.cnt
;
--get counts of source codes
-- when source code is mapped to multiple tables (if source code is mapped to several concepts it's counted several times as well), so we look at source table with least occurrences
--where probably it's mapped to one concept, in theory we can devide the numeric value to the number of target concepts per source concept
create table #sourceConceptCount as
select stratum_1 as source_concept_id, min (count_value) as totalcount
from
@resultSchema.achilles_results
where analysis_id in (425 -- condition_source_concept_id
,625 -- procedure_source_concept_id
,725 -- drug_source_concept_id
,825 -- observation_source_concept_id
,1825 -- measurement_source_concept_id
,2125 -- device_source_concept_id
)
group by  stratum_1
;
--2. get the Node concepts that became non-standard and show their replacements
create table #non_st_Nodes as 
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , coalesce (aro.descendant_record_count, 0) as drc,
cm.concept_id as maps_to_concept_id, cm.concept_name as maps_to_concept_name,
cmv.concept_id as maps_to_value_concept_id, cmv.concept_name as maps_to_value_concept_name
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid and cn.standard_concept is null
left join #achilles_result_cc aro on aro.concept_id = cn.concept_id 
left join @newVocabSchema.concept_relationship cr on cr.concept_id_1 = cn.concept_id and cr.relationship_id ='Maps to'
left join @newVocabSchema.concept cm on cm.concept_id = cr.concept_id_2 
left join @newVocabSchema.concept_relationship crv on crv.concept_id_1 = cn.concept_id and crv.relationship_id ='Maps to value'
left join @newVocabSchema.concept cmv on cmv.concept_id = crv.concept_id_2 
order by drc desc
;
--3. get difference in target concepts
--resolve concept sets
--old vocabulary vs new, target concept comparison
create table #resolv_dif0  as 
with old_vc as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
except
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
)
,
new_vc as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
except
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
)
select *, 'Removed' as action from (
select * from old_vc 
except 
select * from new_vc 
)
union all
select *, 'Added' as action from (
select * from new_vc 
except 
select * from old_vc 
)
;
alter table #resolv_dif0
RENAME descendant_concept_id TO concept_id
;
create table #resolv_dif as
with addexc as (
select cohortid, conceptsetname, conceptsetid, concept_id from #resolv_dif0 a
join #resolv_dif0 b using (cohortid, conceptsetname, conceptsetid, concept_id)
where a.action ='Added' and b.action ='Removed'
)
select * from #resolv_dif0  where (cohortid, conceptsetname, conceptsetid, concept_id) not in (select * from addexc)
;
--aggregate output by peaks, the peak is a highest in a hierarchy amongs concepts added or removed
create table #resolv_dif_peaks as
-- concepts that are descendants to be excluded from the output
with descnds as (
select a.cohortid, a.conceptsetid, a.isexcluded, a.includedescendants , 
 a.Node_concept_id , a.node_concept_name , b.concept_id, a.action 
from #resolv_dif a
--concept_ancestor of the new vocab since the output will be used in cohort fix to be used with a NEW vocabulary
join @newVocabSchema.concept_ancestor an on ancestor_concept_id = a.concept_id 
join #resolv_dif b on descendant_concept_id = b.concept_id
and a.cohortid = b.cohortid and a.conceptsetid = b.conceptsetid and a.node_concept_id = b.node_concept_id and a.action = b.action
and a.isexcluded = b.isexcluded and a.includedescendants = b.includedescendants
where  an.ancestor_concept_id !=an.descendant_concept_id 
)
select a.cohortid, a.conceptsetid, a.conceptsetname, a.isexcluded, a.includedescendants , 
 a.Node_concept_id , a.node_concept_name ,  a.action , a.concept_id as peak_concept_id,
 c.concept_name as peak_name, c.concept_code as peak_code , coalesce (aro.descendant_record_count , 0) as drc
  from #resolv_dif a
-- to exclude non-standard concepts from peaks (later it will be done anyway)
--might be viewed within a node 
left join descnds d on a.cohortid = d.cohortid and a.conceptsetid = d.conceptsetid and d.concept_id = a.concept_id and a.node_concept_id = d.node_concept_id 
and a.isexcluded = d.isexcluded and a.includedescendants = d.includedescendants
and a.action = d.action
--add counts
left join #achilles_result_cc aro on aro.concept_id = a.concept_id 
-- add concept information
join @newVocabSchema.concept c on c.concept_id = a.concept_id 
where d.concept_id is null
;
--look at the mapping difference
--old vocabulary vs new, source concept comparison
create table #resolv_dif_sc0  as 
with old_vc as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
except
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
)
,
old_vc_map as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
 Node_concept_id , node_concept_name, r.concept_id_2 as source_concept_id
 from old_vc
join @oldVocabSchema.concept_relationship r on descendant_concept_id = r.concept_id_1 and r.relationship_id ='Mapped from'
)
,
new_vc as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
except
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
),
new_vc_map as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
 Node_concept_id , node_concept_name, r.concept_id_2 as source_concept_id
 from new_vc
join @newVocabSchema.concept_relationship r on descendant_concept_id = r.concept_id_1 and r.relationship_id ='Mapped from'
)
select *, 'Removed' as action from (
select * from old_vc_map
except 
select * from new_vc_map 
)
union all
select *, 'Added' as action from (
select * from new_vc_map 
except 
select * from old_vc_map 
)
;
--if concept is added and removed within the same concept set but in different nodes it shouldn't be shown
--filtering by node concept or by source concepts
create table #resolv_dif_sc as
with addexc as (
select cohortid, conceptsetname, conceptsetid, source_concept_id from #resolv_dif_sc0 a
join #resolv_dif_sc0 b using (cohortid, conceptsetname, conceptsetid, source_concept_id)
where a."action" ='Added' and b."action" ='Removed'
)
select dif.*, sc.totalcount  from #resolv_dif_sc0 dif
join #sourceConceptCount sc on dif.source_concept_id = sc.source_concept_id
/* -- excessive functionality
--allows to exlude by node concept
left join #excl_node en using (node_concept_id) 
 -- filter out source concepts 
-- Rule description: 'exc_and', 'exc_or' excludes domain AND OR vocabulary_id respectively
 -- 'inc_or', 'inc_and' includes source concepts inly with specified vocabulary_id OR AND domain_id
join @newVocabSchema.concept c on c.concept_id = dif.source_concept_id
--use the table with the Source concepts excluded from the analysis and specfic rules
left join #source_concept_rules sr on 
(
c.vocabulary_id = sr.vocabulary_id and sr.domain_id = c.domain_id and rule_name in ('exc_and', 'inc_and')
or c.vocabulary_id = sr.vocabulary_id and sr.domain_id = c.domain_id and rule_name in ('exc_or', 'inc_or')
)
*/
where (cohortid, conceptsetname, conceptsetid, dif.source_concept_id) not in (select * from addexc)
and node_concept_id not in (@excludedNodes)
/*
--part of source concept filter
and (sr.rule_name is null or sr.rule_name in ('inc_or', 'inc_and'))
--part of node concept filter
and en.node_concept_id is null
*/
;
--added or removed source concepts with their old and new mappings so we can track these changes: previous table joined with old and new concept_relationship tables with 'Maps to'
--Maps to value is ommitted, otherwise the result will be to cumbersome
;
--append mappings to difference in source concepts, previous vocabulary version
-- listagg and join of this and #newmap table will be done in R
create table #oldmap as 
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants, node_concept_id, node_concept_name, action, totalcount, 
source_concept_id, cs.concept_name as source_concept_name, cs.vocabulary_id as source_vocabulary_id, cs.concept_code as source_concept_code, 
c.concept_id , c.concept_name, c.vocabulary_id, c.concept_code
from #resolv_dif_sc dif  
join @newVocabSchema.concept cs on cs.concept_id = dif.source_concept_id -- to get source_concept_id info
left join @oldVocabSchema.concept_relationship cr on cr.concept_id_1 = dif.source_concept_id and cr.relationship_id ='Maps to' 
left join @oldVocabSchema.concept c on c.concept_id = cr.concept_id_2 
;
--append mappings to difference in source concepts, new vocabulary version
create table #newmap as 
select dif.*,c.concept_id , c.concept_name, c.vocabulary_id, c.concept_code
from #resolv_dif_sc dif  
left join @newVocabSchema.concept_relationship cr on cr.concept_id_1 = dif.source_concept_id and cr.relationship_id ='Maps to' 
left join @newVocabSchema.concept c on c.concept_id = cr.concept_id_2 
;
--domain difference
--old vocabulary vs new, target concept comparison
create table #resolv_dom_dif  as 
with old_vc as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
except
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
)
,
new_vc as (
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
except
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
cn.concept_id as Node_concept_id , cn.concept_name as node_concept_name , ca.descendant_concept_id 
from #ConceptsInCohortSet s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id 
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
)
select cohortid, conceptsetname, conceptsetid, isexcluded, includedescendants , 
 Node_concept_id ,  node_concept_name, 
 cn.concept_id , cn.concept_name , cn.vocabulary_id , cn.concept_code , co.domain_id as old_domain_id, cn.domain_id as new_domain_id,
 aro.descendant_record_count as drc
 from (
select * from old_vc 
intersect 
select * from new_vc 
)
join @oldVocabSchema.concept co on co.concept_id =descendant_concept_id
join @newVocabSchema.concept cn on cn.concept_id =descendant_concept_id
left join #achilles_result_cc aro on aro.concept_id = cn.concept_id 
where co.domain_id != cn.domain_id 
;