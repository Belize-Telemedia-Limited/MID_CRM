select (select Nm_interface from mid_interface where id_interface = l.id_interface) NM_INTERFACE,
(select DSC_INTERFACE from mid_interface where id_interface = l.id_interface) DESC_INTERFACE,
count(*),id_interface from mid_log_execution l where dt_execution > trunc(sysdate - 30) and cod_system = 46
group by id_interface;
