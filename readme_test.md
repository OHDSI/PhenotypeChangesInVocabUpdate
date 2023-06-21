<!-- Output copied to clipboard! -->

<!-----

Yay, no errors, warnings, or alerts!

Conversion time: 0.52 seconds.


Using this Markdown file:

1. Paste this output into your source file.
2. See the notes and action items below regarding this conversion run.
3. Check the rendered output (headings, lists, code blocks, tables) for proper
   formatting and use a linkchecker before you publish this page.

Conversion notes:

* Docs to Markdown version 1.0β34
* Wed Jun 21 2023 08:24:22 GMT-0700 (PDT)
* Source doc: Untitled document
* Tables are currently converted to HTML tables.
----->


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

cohortid | action | sum

123      | Removed| 25     

2. nonStNodes

lists non-standard concepts used in the concept set definition.

Note, the concept set definition JSON isn't updated with the vocabulary updates, so you will not see concept changes in Atlas.

So you need to run this tool to see non-stanard concepts (added by mistake or become non-standard over time)

For example, the cohort_id 123 has conceptset ='depressoin' which has Node concept = "4059192|History of depression" with descendants included, 

this concept is non-standard and mapped this way:

Maps to "1340204|History of event"

Maps to value "440383|Depressive disorder"

In this situation you'll get the following output:

cohortid | conceptsetname | conceptsetid | isexcluded | includedescendants | nodeConceptId | nodeConceptName       | drc   | mapsToConceptId | mapsToConceptName | mapsToValueConceptId | mapsToValueConceptName

123      | depressoin     |        1     |    0       |      1             | 4059192       | History of depression | 45678 | 1340204         | History of event  |      440383          |Depressive disorder

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

cohortid	conceptsetid	conceptsetname	isexcluded	includedescendants	nodeConceptId	nodeConceptName	action	peakConceptId	peakName	peakCode	drc

cohortid	12825

conceptsetid	23

conceptsetname	Headache

isexcluded	0

includedescendants	1

nodeConceptId	378253

nodeConceptName	Headache

action	Added

peakConceptId	375527

peakName	Headache disorder

peakCode	230461009

drc	34219562

5. domainChange

cohortid	conceptsetname	conceptsetid	isexcluded	includedescendants	nodeConceptId	nodeConceptName	conceptId	conceptName	vocabularyId	conceptCode	oldDomainId	newDomainId	drc

10656	Treatment or investigation for TMA	20	0	1	4182536	Transfusion	2108163	Therapeutic apheresis; for plasma pheresis	CPT4	36514	Procedure	Measurement	1010478
