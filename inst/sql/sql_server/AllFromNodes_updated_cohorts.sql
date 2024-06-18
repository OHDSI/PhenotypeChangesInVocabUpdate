--1. look at the mapping difference between old cohort on old vocabulary VS new cohort on a new vocabulary
--old vocabulary vs new, source concept comparison
create table #old_vc as
select cohortid, conceptsetname, conceptsetid, ca.descendant_concept_id
from #ConceptsInCohortSetOld s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
--exclude visits nodes, !!! need to make it as an variable
and s.conceptid not in (@excludedNodes)
except
select cohortid, conceptsetname, conceptsetid , ca.descendant_concept_id
from #ConceptsInCohortSetOld s
join @oldVocabSchema.concept cn on cn.concept_id = s.conceptid
join @oldVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
;
create table #new_vc
 as
select cohortid, conceptsetname, conceptsetid, ca.descendant_concept_id
from #ConceptsInCohortSetNew s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 0
--exclude specific nodes from analysis
and s.conceptid not in (@excludedNodes)
except
select cohortid, conceptsetname, conceptsetid , ca.descendant_concept_id
from #ConceptsInCohortSetNew s
join @newVocabSchema.concept cn on cn.concept_id = s.conceptid
join @newVocabSchema.concept_ancestor ca on ca.ancestor_concept_id = cn.concept_id
and ((includedescendants = 0 and ca.ancestor_concept_id = ca.descendant_concept_id ) or includedescendants != 0)
and isexcluded = 1
;
create table #resolv_dif_sc as 
with
old_vc_map as (
select cohortid, conceptsetname, conceptsetid, r.concept_id_2 as source_concept_id
 from #old_vc
join @oldVocabSchema.concept_relationship r on descendant_concept_id = r.concept_id_1 and r.relationship_id ='Mapped from'
)
,
new_vc_map as (
select c.old_cohort_id as cohortid, conceptsetname, conceptsetid,  r.concept_id_2 as source_concept_id
 from #new_vc vc
 join #cohorts c on c.new_cohort_id = vc.cohortid
join @newVocabSchema.concept_relationship r on descendant_concept_id = r.concept_id_1 and r.relationship_id ='Mapped from'
)
select *, 'Removed' as action from (
select * from old_vc_map
except
select * from new_vc_map
) a
union all
select *, 'Added' as action from (
select * from new_vc_map
except
select * from old_vc_map
) a
;
--append mappings to see difference in source concepts, previous vocabulary version
-- listagg and join of this and #newmap table will be done in R
--afterwards, these tables are joined in R
create table #oldmap as
with aaa as (select 1 as test)
select cohortid, conceptsetname, conceptsetid, action, record_count ,
source_concept_id, cs.concept_name as source_concept_name, cs.vocabulary_id as source_vocabulary_id, cs.concept_code as source_concept_code,
c.concept_id , c.concept_name, c.vocabulary_id, c.concept_code
from #resolv_dif_sc dif
join @newVocabSchema.concept cs on cs.concept_id = dif.source_concept_id -- to get source_concept_id info
left join @oldVocabSchema.concept_relationship cr on cr.concept_id_1 = dif.source_concept_id and cr.relationship_id ='Maps to'
left join @oldVocabSchema.concept c on c.concept_id = cr.concept_id_2
join @resultSchema.achilles_result_cc arc on arc.concept_id = cs.concept_id 
--look only at specific vocabularies that used by our data
{@includedSourceVocabs !=0} ? {where cs.vocabulary_id in (@includedSourceVocabs)}
;
--append mappings to see difference in source concepts, new vocabulary version
create table #newmap as
with aaa as (select 1 as test)
select dif.*,c.concept_id , c.concept_name, c.vocabulary_id, c.concept_code
from #resolv_dif_sc dif
left join @newVocabSchema.concept_relationship cr on cr.concept_id_1 = dif.source_concept_id and cr.relationship_id ='Maps to'
left join @newVocabSchema.concept c on c.concept_id = cr.concept_id_2
;
--3. domain difference
--old vocabulary vs new, target concept comparison
create table #resolv_dom_dif  as
select cohortid, conceptsetname, conceptsetid, 
 cn.concept_id , cn.concept_name , cn.vocabulary_id ,
 cs.concept_code as source_concept_code, cs.concept_name as source_concept_name, cs.vocabulary_id as source_vocabulary_id,
 co.domain_id as old_domain_id, cn.domain_id as new_domain_id,
 coalesce (aro.record_count, 0) as source_concept_record_count
 from (
select * from #old_vc
--compare only rows where same included concepts exist
intersect 
select c.old_cohort_id as cohortid, conceptsetname, conceptsetid, descendant_concept_id from #new_vc vc
join #cohorts c on c.new_cohort_id = vc.cohortid
) a
join @oldVocabSchema.concept co on co.concept_id =descendant_concept_id
join @newVocabSchema.concept cn on cn.concept_id =descendant_concept_id
--get source concepts related to those targets with changed domains
join @newVocabSchema.concept_relationship cr on cr.relationship_id ='Mapped from' and cr.concept_id_1 = cn.concept_id 
join @newVocabSchema.concept cs on cs.concept_id = cr.concept_id_2
left join @resultSchema.achilles_result_cc aro on aro.concept_id = cs.concept_id
where co.domain_id != cn.domain_id
{@includedSourceVocabs !=0}? {and cs.vocabulary_id in (@includedSourceVocabs)}
;