The output description:

Writes an Excel file to disk. 

definitions used:

"Node concept" is a concept directly used in Concept Set Expression

"includedescendants": indicates whether descendants of "Node concept" are included in concept set, 0 stands for False, 1 stands for True

"isexcluded": indicates whether "Node concept" and it's descendants if "includedescendants" = 1 are excluded from a concept set, 0 stands for False, 1 stands for True

"drc": descendant record count - summary number of 

"source concept": the concept set definition is usualy done through standard concepts. 

Different clinical events might be captured with the same set of included standard concepts if mapping was changed, that's why the tool tracks source concepts related.

The Excel file has the following tabs:

1. summaryTable 

sum of added or removed source concepts occurrences in a dataset

- for example, the cohort_id 123 doesn't pick up source codes X and Y  when using newer vocabulary version. X appears 10 times in the data, Y appears 15 times.

In this situation you'll get the following output:


<table>
  <tr>
   <td>cohortid
   </td>
   <td>123
   </td>
  </tr>
  <tr>
   <td>action
   </td>
   <td>Removed
   </td>
  </tr>
  <tr>
   <td>sum
   </td>
   <td>25
   </td>
  </tr>
</table>


 

2. nonStNodes

lists non-standard concepts used in the concept set definition.

Note, the concept set definition JSON isn't updated with the vocabulary updates, so you will not see concept changes in Atlas.

So you need to run this tool to see non-stanard concepts (added by mistake or become non-standard over time)

For example, the cohort_id 123 has conceptset ='depressoin' which has Node concept = "4059192|History of depression" with descendants included, 

this concept is non-standard and mapped this way:

Maps to "1340204|History of event"

Maps to value "440383|Depressive disorder"

In this situation you'll get the following output:


<table>
  <tr>
   <td>cohortid
   </td>
   <td>10729
   </td>
  </tr>
  <tr>
   <td>conceptsetname
   </td>
   <td>Malignancies that spread to liver
   </td>
  </tr>
  <tr>
   <td>conceptsetid
   </td>
   <td>15
   </td>
  </tr>
  <tr>
   <td>isexcluded
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>includedescendants
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>nodeConceptId
   </td>
   <td>4324190
   </td>
  </tr>
  <tr>
   <td>nodeConceptName
   </td>
   <td>History of malignant neoplasm of breast
   </td>
  </tr>
  <tr>
   <td>drc
   </td>
   <td>20284048
   </td>
  </tr>
  <tr>
   <td>mapsToConceptId
   </td>
   <td>1340204
   </td>
  </tr>
  <tr>
   <td>mapsToConceptName
   </td>
   <td>History of event
   </td>
  </tr>
  <tr>
   <td>mapsToValueConceptId
   </td>
   <td>4112853
   </td>
  </tr>
  <tr>
   <td>mapsToValueConceptName
   </td>
   <td>Malignant tumor of breast
   </td>
  </tr>
</table>


3. mapDif

Shows related source concepts that were added or removed with their mapping for reference. 

This way user knows why the difference in related source concepts occurrs.

For example, 

- !!! first part is common for 3 checks, explain it in the begeninning


<table>
  <tr>
   <td>COHORTID
   </td>
   <td>12822
   </td>
  </tr>
  <tr>
   <td>CONCEPTSETNAME
   </td>
   <td>Cranial nerve disorder (excluding Bell's palsy and not related to infection or neoplasm)
   </td>
  </tr>
  <tr>
   <td>CONCEPTSETID
   </td>
   <td>28
   </td>
  </tr>
  <tr>
   <td>ISEXCLUDED
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>INCLUDEDESCENDANTS
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>NODE_CONCEPT_ID
   </td>
   <td>441848
   </td>
  </tr>
  <tr>
   <td>NODE_CONCEPT_NAME
   </td>
   <td>Cranial nerve disorder
   </td>
  </tr>
  <tr>
   <td>SOURCE_CONCEPT_ID
   </td>
   <td>44823107
   </td>
  </tr>
  <tr>
   <td>sourceCodesCount
   </td>
   <td>7115
   </td>
  </tr>
  <tr>
   <td>ACTION
   </td>
   <td>Added
   </td>
  </tr>
  <tr>
   <td>SOURCE_CONCEPT_NAME
   </td>
   <td>Neural hearing loss, unilateral
   </td>
  </tr>
  <tr>
   <td>SOURCE_VOCABULARY_ID
   </td>
   <td>ICD9CM
   </td>
  </tr>
  <tr>
   <td>SOURCE_CONCEPT_CODE
   </td>
   <td>389.13
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_CONCEPT_ID
   </td>
   <td>379831
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_CONCEPT_NAME
   </td>
   <td>Unilateral neural hearing loss
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_VOCABULARY_ID
   </td>
   <td>SNOMED
   </td>
  </tr>
  <tr>
   <td>OLD_MAPPED_CONCEPT_CODE
   </td>
   <td>425601005
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_CONCEPT_ID
   </td>
   <td>381312
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_CONCEPT_NAME
   </td>
   <td>Neural hearing loss
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_VOCABULARY_ID
   </td>
   <td>SNOMED
   </td>
  </tr>
  <tr>
   <td>NEW_MAPPED_CONCEPT_CODE
   </td>
   <td>73371001
   </td>
  </tr>
</table>


4.peakDif

"Peak concept": the common parent concept of added or removed standard concepts above which the hierarchy is changed


<table>
  <tr>
   <td>cohortid
   </td>
   <td>12825
   </td>
  </tr>
  <tr>
   <td>conceptsetid
   </td>
   <td>23
   </td>
  </tr>
  <tr>
   <td>conceptsetname
   </td>
   <td>Headache
   </td>
  </tr>
  <tr>
   <td>isexcluded
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>includedescendants
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>nodeConceptId
   </td>
   <td>378253
   </td>
  </tr>
  <tr>
   <td>nodeConceptName
   </td>
   <td>Headache
   </td>
  </tr>
  <tr>
   <td>action
   </td>
   <td>Added
   </td>
  </tr>
  <tr>
   <td><strong>peakConceptId</strong>
   </td>
   <td><strong>375527</strong>
   </td>
  </tr>
  <tr>
   <td><strong>peakName</strong>
   </td>
   <td><strong>Headache disorder</strong>
   </td>
  </tr>
  <tr>
   <td>peakCode
   </td>
   <td>230461009
   </td>
  </tr>
  <tr>
   <td>drc
   </td>
   <td>34219562
   </td>
  </tr>
</table>


5. domainChange


<table>
  <tr>
   <td>cohortid
   </td>
   <td>10656
   </td>
  </tr>
  <tr>
   <td>conceptsetname
   </td>
   <td>Treatment or investigation for TMA
   </td>
  </tr>
  <tr>
   <td>conceptsetid
   </td>
   <td>20
   </td>
  </tr>
  <tr>
   <td>isexcluded
   </td>
   <td>0
   </td>
  </tr>
  <tr>
   <td>includedescendants
   </td>
   <td>1
   </td>
  </tr>
  <tr>
   <td>nodeConceptId
   </td>
   <td>4182536
   </td>
  </tr>
  <tr>
   <td>nodeConceptName
   </td>
   <td>Transfusion
   </td>
  </tr>
  <tr>
   <td>conceptId
   </td>
   <td>2108163
   </td>
  </tr>
  <tr>
   <td>conceptName
   </td>
   <td>Therapeutic apheresis; for plasma pheresis
   </td>
  </tr>
  <tr>
   <td>vocabularyId
   </td>
   <td>CPT4
   </td>
  </tr>
  <tr>
   <td>conceptCode
   </td>
   <td>36514
   </td>
  </tr>
  <tr>
   <td><strong>oldDomainId</strong>
   </td>
   <td><strong>Procedure</strong>
   </td>
  </tr>
  <tr>
   <td><strong>newDomainId</strong>
   </td>
   <td><strong>Measurement</strong>
   </td>
  </tr>
  <tr>
   <td>drc
   </td>
   <td>1010478
   </td>
  </tr>
</table>